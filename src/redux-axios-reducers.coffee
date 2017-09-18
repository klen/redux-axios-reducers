assign = (target, objs...) ->
    for obj in objs
        continue unless obj?
        target[k] = obj[k] for k of obj
    return target


class AxiosReducer

    default:
        data: null
        error: null
        fetching: false

    # Construct types and configuration
    constructor: (@config={}) ->
        @config.name ?= 'noname'
        @config.baseURL ?= "/#{@name}"

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

    reduceSuccess: (state, action) -> data: action.response.data, fetching: false

    reduceError: (state, action) -> error: action.error, fetching: false

    fetch: (config={}) => (dispatch) =>

        config = @transformConfig(config)

        dispatch type: @TYPES.FETCHING, config: config
        return @axios.request config
            .then (response) =>
                response.data = @transformData(response.data)
                dispatch
                    type: @TYPES.FETCH_SUCCESS
                    config: config
                    response: response

            .catch (error) =>
                console?.error(error)
                dispatch
                    type: @TYPES.FETCH_ERROR
                    config: config
                    error: error

    transformConfig: (config) ->
        return assign {method: 'get', url: @config.baseURL}, config

    transformData: (data) -> data


class AxiosRESTReducer extends AxiosReducer

    default:
        byId: {}
        data: []
        error: null
        fetching: false

    reduceSuccess: (state, action) ->
        state.data = [] if action.config.method == 'get' and not action.config.id

        data = if Array.isArray(action.response.data) then action.response.data else [action.response.data]
        for item in data
            continue unless item and item.id
            state.byId[item.id] = item
            state.data.push(item.id) unless action.config.id

        if action.config.method == 'delete' and action.config.id
            state.data = (id for id in state.data when id != action.config.id)

        return fetching: false

    transformConfig: (config) ->
        config = super(config)
        config.url += "/#{config.id}" if config.id
        return config

    # Iterate through loaded data
    iterate: =>
        state = @getState()
        return [] unless state.data
        return (state.byId[id] for id in state.data)

    update: (config={}) =>
        config = assign {}, data: config unless config.data
        config = assign {}, config, id: config.data.id, method: if config.data.id then 'put' else 'post'
        return @fetch(config)

    remove: (config={}) =>
        config.method = 'delete'
        return @fetch(assign {}, config, method: 'delete')

module.exports =
    AxiosReducer: AxiosReducer
    AxiosRESTReducer: AxiosRESTReducer
