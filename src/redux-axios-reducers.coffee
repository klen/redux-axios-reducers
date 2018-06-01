Axios = require('axios')

class AxiosReducer

  initial:
    data: null
    error: null
    fetching: null

  # Construct types and defaults
  constructor: (@defaults={}) ->

    @initial = {@initial...}

    @defaults.axios   ?= Axios
    @defaults.name    ?= 'noname'
    @defaults.prefix  ?= 'API'
    @defaults.baseURL ?= "/#{@defaults.name}"

    @actions = {@fetch, @update, @get, @post, @put, @patch, @remove}

    name = @defaults.name.toUpperCase()
    @TYPES =
      FETCHING: "#{@defaults.prefix}/#{name}/FETCHING"
      FETCH_FAIL: "#{@defaults.prefix}/#{name}/FETCH_FAIL"
      FETCH_SUCCESS: "#{@defaults.prefix}/#{name}/FETCH_SUCCESS"
      RESET: "#{@defaults.prefix}/#{name}/RESET"
      UPDATE: "#{@defaults.prefix}/#{name}/UPDATE"

    @reducers =
      "#{@TYPES.FETCHING}": @reduceFetching
      "#{@TYPES.FETCH_FAIL}": @reduceFail
      "#{@TYPES.FETCH_SUCCESS}": @reduceSuccess
      "#{@TYPES.RESET}": => @initial
      "#{@TYPES.UPDATE}": (state, action) -> {state..., action.payload...}

  # Init reducer
  configure: (defaults) ->

    state_ = null

    @getState = -> {state_...}

    @defaults = {@defaults..., defaults...} if defaults

    # Create Reducer
    return (state=@initial, action) =>
      reducer = @reducers[action.type]
      return state_ = if reducer then reducer(state, action) else state

  modifyReducer: (type, reducer) ->
    type = type.toUpperCase()
    @TYPES[type] = "#{@defaults.prefix}/#{@defaults.name.toUpperCase()}/#{type}"
    @reducers[@TYPES[type]] = reducer

  # Reducers
  reduceFetching: (state) =>
    return {state..., fetching: true}

  reduceSuccess: (state, action) =>
    return {
        state...,
        data: action.payload.response.data,
        error: null,
        fetching: false,
    }

  reduceFail: (state, action) =>
    return {
        state...,
        error: action.error
        fetching: false
    }

  # Make a request with axios (global or configured instance)
  request: (config) =>

    unless @defaults.axios and @defaults.axios.request
      throw new Error(
        "Please configure the reducer '#{@defaults.name}' before first use.")

    return @defaults.axios.request(config)

  # Process request
  fetch: (config={}) => (dispatch) =>

    config = @transformConfig(config)

    cancel = null
    config = {config..., cancelToken: new Axios.CancelToken(
      (c) -> cancel = c
    )}

    dispatch type: @TYPES.FETCHING, payload: config: config unless config.ignore

    promise = @request(config)

      .then (response) =>
        response.data = @transformData(response.data)
        unless config.ignore
          dispatch
            type: @TYPES.FETCH_SUCCESS
            payload:
                config: config
                response: response

        return response

      .catch (error) =>
        console?.error(error)
        unless config.ignore
          dispatch
            type: @TYPES.FETCH_FAIL
            payload: config: config
            error: if Axios.isCancel(error) then null else error

        throw error

    promise.cancel = cancel
    return promise

  transformConfig: (config) ->
    return {
      config...,
      method: config.method or 'get'
      url: config.url or @defaults.baseURL}

  transformData: (data) -> data

  getItemId: (item) -> item.id

  update: (config={}) =>
    id = config and @getItemId(config) or config.data and @getItemId(config.data)
    return if id then @put(config) else @post(config)

  get: (config) => @fetch(config)

  post: (config={}) =>
    config = {data: config} unless config.data
    config = {config..., method: config.method or 'post'}
    @fetch(config)

  put: (config={}) =>
    config = {data: config} unless config.data
    config = {config..., method: config.method or 'put'}
    @fetch(config)

  patch: (config={}) =>
    config = {data: config} unless config.data
    config = {config..., method: config.method or 'patch'}
    @fetch(config)

  remove: (config={}) =>
    config = {config..., method: config.method or 'delete'}
    @fetch(config)


class AxiosRESTReducer extends AxiosReducer

  constructor: (defaults) ->
    super(defaults)

    @initial.byId = {}
    @initial.data = []

  reduceSuccess: (state, {payload}) ->
    singleId = @getItemId(payload.config) or (
      payload.config.data and @getItemId(payload.config.data))

    state.data = [] if payload.config.method == 'get' and not singleId
    data = payload.response.data
    data = [data] unless Array.isArray(data)

    for item in data
      continue unless item and @getItemId(item)
      id = @getItemId(item)
      state.byId = { state.byId..., [id]: item }
      state.data = [state.data..., id] unless singleId

    if payload.config.method == 'delete' and singleId
      delete state.byId[singleId]
      state.byId = {state.byId...}
      state.data = (id for id in state.data when id != singleId)

    return {state..., fetching: false, error: null}

  transformConfig: (config) ->
    config = super(config)
    id = (
      @getItemId(config) or
      (config.data and @getItemId(config.data)) or
      (config.params and @getItemId(config.params))
    )
    config.url += "/#{id}" if id
    return config

  # Iterate through loaded data
  iterate: =>
    state = @getState()
    return [] unless state.data
    return (state.byId[id] for id in state.data)

module.exports = { AxiosReducer, AxiosRESTReducer }
