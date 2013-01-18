{expect} = require '../util'
setup = require '../util/singleProcessStack'

describe 'filter integration', ->
  describe 'bundling', ->
    it 'should be able to unbundle the same function-powered filter in the browser', (done) ->
      run = setup
        browserA:
          tabA:
            server: (req, serverModel, bundleModel, store) ->
              store.set 'users.1.name', 'Brian', null, (err) ->
                expect(err).to.be.null()
                store.set 'users.2.name', 'Nate', null, (err) ->
                  serverModel.fetch 'users', (err, users) ->
                    filter = serverModel.filter 'users', (user) ->
                      user.name.charAt(0) == 'B'
                    serverModel.ref '_b', filter
                    expect(serverModel.get('_b.length')).to.equal 1
                    expect(serverModel.get('_b.0.name')).to.equal 'Brian'
                    bundleModel serverModel
            browser: (model) ->
              expect(model.get('_b.length')).to.equal 1
              expect(model.get('_b.0.name')).to.equal 'Brian'
            onSocketCxn: (socket) ->
              socket.on 'disconnect', ->
                teardown done
              socket.disconnect 'booted'

      teardown = run()

    it 'should be able to leverage the model inside a filter function in the browser', (done) ->
      run = setup
        browserA:
          tabA:
            server: (req, serverModel, bundleModel, store) ->
              store.set 'users.1.name', 'Brian', null, (err) ->
                expect(err).to.be.null()
                store.set 'users.2.name', 'Nate', null, (err) ->
                  serverModel.set '_letter', 'B'
                  serverModel.fetch 'users', (err, users) ->
                    filter = serverModel.filter 'users', (user, id, model) ->
                      user.name.charAt(0) == model.get '_letter'
                    serverModel.ref '_b', filter
                    expect(serverModel.get('_b.length')).to.equal 1
                    expect(serverModel.get('_b.0.name')).to.equal 'Brian'
                    bundleModel serverModel
            browser: (model) ->
              expect(model.get('_b.length')).to.equal 1
              expect(model.get('_b.0.name')).to.equal 'Brian'
            onSocketCxn: (socket) ->
              socket.on 'disconnect', ->
                teardown done
              socket.disconnect 'booted'

      teardown = run()

  describe 'preservation', ->
    it 'should be able to load the same filtered results in the browser xxx', (done) ->
      run = setup
        browserA:
          tabA:
            server: (req, serverModel, bundleModel, store) ->
              store.query.expose 'users',
                olderThan: (age) -> @where('age').gt(age)
              store.set 'users.1', id: 1, name: 'Brian', age: 27, null, (err) ->
                expect(err).to.be.null()
                store.set 'users.2', id: 2, name: 'Nate', age: 28, null, (err) ->
                  serverModel.query('users').olderThan(25).fetch (err, $users) ->
                    serverModel.set '_letter', 'B'
                    filter = serverModel.filter $users, (user, id, model) ->
                      user.name.charAt(0) == model.get '_letter'
                    serverModel.ref '_b', filter
                    expect(serverModel.get('_b.length')).to.equal 1
                    expect(serverModel.get('_b.0.name')).to.equal 'Brian'
                    bundleModel serverModel
            browser: (model) ->
              expect(model.get('_b.length')).to.equal 1
              expect(model.get('_b.0.name')).to.equal 'Brian'
            onSocketCxn: (socket) ->
              socket.on 'disconnect', ->
                teardown done
              socket.disconnect 'booted'

      teardown = run()
