assign = (target, objs...) ->
  for obj in objs
    continue unless obj?
    target[k] = obj[k] for k of obj
  return target


class AxiosReducer

  default:
    data: null
    error: null
    fetching: null

  # Construct types and configuration
  constructor: (@config={}) ->
    @config.name ?= 'noname'
    @config.baseURL ?= "/#{@name}"
    @default = assign {}, @default

    name = @config.name.toUpperCase()
    @TYPES = {
      FETCHING: "ASYNC/#{name}/FETCHING"
      FETCH_ERROR: "ASYNC/#{name}/FETCH_ERROR"
      FETCH_SUCCESS: "ASYNC/#{name}/FETCH_SUCCESS"
    }

    # Init reducer
  configure: (@axios, config) ->

    selfState = null

    @getState = -> assign({}, selfState)

    @config = assign(@config, config) if config

    # Create Reducer
    return (state=@default, action) =>
      return selfState = switch action.type

        when @TYPES.FETCHING
          assign {}, state, @reduceFetching(state, action)

        when @TYPES.FETCH_SUCCESS
          assign {}, state, @reduceSuccess(state, action)

        when @TYPES.FETCH_ERROR
          assign {}, state, @reduceError(state, action)

        else state

  reduceFetching: -> fetching: true

  reduceSuccess: (state, action) ->
    data: action.response.data
    fetching: false
    error: null

  reduceError: (state, action) -> error: action.error, fetching: false

  fetch: (config={}) -> (dispatch) =>

    config = @transformConfig(config)

    dispatch type: @TYPES.FETCHING, config: config
    return @axios.request config
      .then (response) =>
        response.data = @transformData(response.data)
        dispatch
          type: @TYPES.FETCH_SUCCESS
          config: config
          response: response

        return response

      .catch (error) =>
        console?.error(error)
        dispatch
          type: @TYPES.FETCH_ERROR
          config: config
          error: error

        return error

  get: @fetch

  post: (config={}) =>
    config = assign {}, data: config unless config.data
    config = assign {method: 'post'}, config
    @fetch(config)

  put: (config={}) =>
    config = assign {}, data: config unless config.data
    config = assign {method: 'put', id: config.data.id}, config
    @fetch(config)

  patch: @put

  remove: (config={}) =>
    @fetch(assign {method: 'delete'}, config)

  update: (config) ->
    return @put(config) if config.data and config.data.id or config.id
    return @post(config)

  transformConfig: (config) ->
    assign {method: 'get', url: @config.baseURL}, config

  transformData: (data) -> data


class AxiosRESTReducer extends AxiosReducer

  constructor: (config) ->
    super(config)

    @default.byId = {}
    @default.data = []

  reduceSuccess: (state, action) ->
    state.data = [] if action.config.method == 'get' and not action.config.id
    data = action.response.data
    data = [data] unless Array.isArray(data)

    for item in data
      continue unless item and item.id
      state.byId[item.id] = item
      state.data.push(item.id) unless action.config.id

    if action.config.method == 'delete' and action.config.id
      state.data = (id for id in state.data when id != action.config.id)

    return fetching: false, error: null

  transformConfig: (config) ->
    config = super(config)
    config.url += "/#{config.id}" if config.id
    return config

  # Iterate through loaded data
  iterate: =>
    state = @getState()
    return [] unless state.data
    return (state.byId[id] for id in state.data)

module.exports =
    AxiosReducer: AxiosReducer
    AxiosRESTReducer: AxiosRESTReducer
