# redux-axios-reducers

[![npm version](https://badge.fury.io/js/redux-axios-reducers.svg)](https://badge.fury.io/js/redux-axios-reducers)

Redux reducers for fetching data with axios HTTP client

## Installation

```bash
npm install --save redux-axios-reducers
```

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
    users: usersReducer.configure(client);
    // application reducers
    ...
});

const store = createStore(reducers)

```

### Dispatch actions

A reducer instance has methods which generate actions and do HTTP requests.

```js

// HTTP GET /api/users
loadUsers = () => usersReducer.get()

loadUsersWithFilter = (status) => usersReducer.get({
    // See Axios documentation for params
    params: {
        status: status
    }
})

// HTTP PUT /api/users/1
updateUsers = (id, data) => usersReducer.put({
    url: 'users/' + id,
    data: data
})

// Redux-thunk middleware
loadUsers = () => (dispatch) => {
    dispatch(
        usersReducer.get()
    ).then( () => {
        // do something else
    })
}

```

### Reduce actions

A reducer is generating TYPES based on given name:

```js

    reducerInstance.TYPES
    {
        FETCHING: `ASYNC/${name.toUpperCase()}/FETCHING`
        FETCH_ERROR: `ASYNC/${name.toUpperCase()}/FETCH_ERROR`
        FETCH_SUCCESS: `ASYNC/${name.toUpperCase()}/SUCCESS`
        
    }
```

So you can use it in your own reducers like `usersReducer.TYPES.FETCH_SUCCESS`

