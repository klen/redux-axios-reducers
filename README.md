# redux-axios-reducers

[![npm version](https://badge.fury.io/js/redux-axios-reducers.svg)](https://badge.fury.io/js/redux-axios-reducers)
[![travis build](https://travis-ci.org/klen/redux-axios-reducers.svg?branch=develop)](https://travis-ci.org/klen/redux-axios-reducers)


Redux reducers for fetching data with axios HTTP client

## Installation

```bash
npm install --save redux-axios-reducers
```

### Dependencies

`redux-axios-reducers` depends on `redux`, `redux-thunk`.

## How to use?

### Configure and connect an Axios reducer

```js

import {createStore, combineReducers} from 'redux';
import {AxiosReducer} from redux-axios-reducer;

const usersReducer = new AxiosReducer({name: 'users'});

const client = axios.create({
  baseURL:'http://localhost:8080/api',
  responseType: 'json'
});

const reducers = combineReducers({

    // You must to call reducer.configure method for provide reduce function into Redux
    users: usersReducer.configure({axios: client});

    // application reducers
    ...
});

const store = createStore(reducers)

```

### Dispatch actions

A reducer instance has methods which generate async (redux-thunk) actions. The
actions do HTTP request.

```js

// HTTP GET /api/users
loadUsers = () => usersReducer.get()

// HTTP GET /api/users?status=active
loadUsersWithFilter = (status) => usersReducer.get({
    // See Axios documentation for params
    params: {
        status: 'active'
    }
})

// HTTP PUT /api/users/1
updateUsers = (id, data) => usersReducer.put({
    url: 'users/' + id,
    data: data
})

// Redux-thunk middleware
loadUsers = () => (dispatch) => {
    dispatch(usersReducer.get())
    .then( () => {
        // do something else
    })
}

// Redux-thunk middleware, chain methods
loadUsersAndComments = () => (dispatch) => {
    Promise.all([
        dispatch(usersReducer.get()),
        dispatch(commentsReducer.get())
    ])
    .then( () => {
        // do something else
    })
}

```

### Reduce actions

A reducer is generating TYPES based on given name:

```js

    reducerInstance.TYPES
    // {
    //     FETCHING: `ASYNC/${name.toUpperCase()}/FETCHING`
    //     FETCH_FAIL: `ASYNC/${name.toUpperCase()}/FETCH_FAIL`
    //     FETCH_SUCCESS: `ASYNC/${name.toUpperCase()}/SUCCESS`
    //     
    // }
```

So you can use it in your own reducers like `usersReducer.TYPES.FETCH_SUCCESS`

### Reducers methods

#### AxiosReducer/AxiosRestReducer

method                  | description
------------------------|------------------------
get/fetch               | HTTP GET accepts AxiosParams
post                    | HTTP POST accepts AxiosParams
put                     | HTTP PUT accepts AxiosParams
patch                   | HTTP PATCH accepts AxiosParams
remove                  | HTTP DELETE accepts AxiosParams

## License

This project is licensed under the MIT license, Copyright (c) 2017 Kirill Klenov. For more information see `LICENSE.md`.

## Acknowledgements

[Dan Abramov](https://github.com/gaearon) for Redux [Matt Zabriskie](https://github.com/mzabriskie) for [Axios](https://github.com/mzabriskie/axios). A Promise based HTTP client for the browser and node.js
