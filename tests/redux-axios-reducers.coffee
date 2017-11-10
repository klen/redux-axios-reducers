configureStore = require('redux-mock-store').default
thunk = require('redux-thunk').default
moxios = require('moxios')

Module = require('../src/redux-axios-reducers.coffee')

exports.AxiosReduxReducers =

    setUp: (callback) ->
        @mockStore = configureStore([thunk])
        moxios.install()
        callback()

    tearDown: (callback) ->
        moxios.uninstall()
        callback()

    'Base tests': (test) ->
        test.ok(Module.AxiosReducer, 'Axios Reducer is here')
        test.ok(Module.AxiosRESTReducer, 'Axios REST Reducer is here')

        test.done()

    'Axios Reducer base tests': (test) ->
        reducer = new Module.AxiosReducer(name: 'resource')
        test.ok(reducer, "Reducer initialized")
        test.ok(reducer.defaults, "Reducer's defaults initialized")
        test.equal(reducer.defaults.name, 'resource')
        test.equal(reducer.defaults.baseURL, '/resource')
        test.equal(reducer.TYPES.FETCHING, 'API/RESOURCE/FETCHING')

        # Initialize a reducer
        reduce = reducer.configure()

        # Initialize State
        state = reduce(undefined, '-')

        # Mock axios
        moxios.stubRequest('/resource',
            status: 200, responseText: '[1, 2, 3]')

        # Create mock store
        store = @mockStore()

        # Fetch data
        store.dispatch reducer.fetch()

        actions = store.getActions()
        test.equal(actions.length, 1)
        action = actions[0]
        test.equal(action.type, reducer.TYPES.FETCHING)

        state = reduce(state, action)
        test.ok(state.fetching)

        store.clearActions()

        moxios.wait ->
            action = store.getActions()[0]
            test.equal(action.type, reducer.TYPES.FETCH_SUCCESS)
            state = reduce(state, action)
            test.deepEqual(state.data, [1, 2, 3])
            test.ok(not state.fetching)

            test.done()

    'Axios REST Reducer base tests': (test) ->
        reducer = new Module.AxiosRESTReducer(name: 'resource')

        reduce = reducer.configure()
        state = reduce(undefined, '-')

        moxios.stubRequest('/resource',
            status: 200, responseText: '[{"id": 1}]')

        store = @mockStore()
        store.dispatch reducer.fetch()

        store.clearActions()

        moxios.wait ->
            action = store.getActions()[0]
            test.equal(action.type, reducer.TYPES.FETCH_SUCCESS)
            state = reduce(state, action)
            test.deepEqual(state.data, [1])
            test.ok(state.byId[1])
            test.ok(not state.fetching)

            test.done()

    'Process errors': (test) ->

        class Reducer extends Module.AxiosReducer

            request: (config) => Promise.reject('Test Exception')

        reducer = new Reducer()

        # Create mock store
        store = @mockStore()

        # Fetch data
        promise = store.dispatch(reducer.fetch())
        promise.catch ->
            test.done()
