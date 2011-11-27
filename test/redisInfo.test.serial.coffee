should = require 'should'
redisInfo = require '../src/redisInfo'
redis = require 'redis'

# Silence console errors in testing
redisInfo._console.error = ->

checkFirstStart = (starts) ->
  starts.length.should.eql 1
  startId = starts[0][0]
  ver = starts[0][1]
  [startTime, startsLength] = startId.split '.'
  (new Date - startTime).should.be.within 0, 100
  startsLength.should.eql '0'
  ver.should.eql '0'

client = null
subClient = null
module.exports =
  setup: (done) ->
    client = redis.createClient()
    subClient = redis.createClient()
    client.flushdb done
  teardown: (done) ->
    client.flushdb ->
      client.end()
      subClient.end()
      done()
  
  'getStarts should work with an uninitialized Redis instance': (done) ->
    redisInfo._getStarts client, (starts) ->
      checkFirstStart starts
      done()
  
  'getStarts should log an error on an uninitialized Redis instance': (done) ->
    redisInfo._console.error = (message) ->
      message.should.be.a 'string'
      redisInfo._console.error = ->
      done()
    redisInfo._getStarts client, ->
  
  'calling getStarts multiple times should work after calling onStart': (done) ->
    redisInfo.onStart client, ->
      client.lrange 'starts', 0, -1, (err, starts) ->
        starts1 = (start.split ',' for start in starts)
        # Delay to make sure start timestamp is different if it gets reset
        setTimeout ->
          redisInfo._getStarts client, (starts2) ->
            starts1.should.eql starts2
            setTimeout ->
              redisInfo._getStarts client, (starts3) ->
                starts1.should.eql starts3
                done()
            , 10
        , 10
  
  'onStart should capture the current version when it is called': (done) ->
    client.set 'ver', 7, ->
      redisInfo.onStart client, ->
        client.set 'ver', 13, ->
          redisInfo._getStarts client, (starts) ->
            ver = starts[0][1]
            ver.should.eql '7'
            done()
  
  'subscribeToStarts should return a list of starts immediately': (done) ->
    redisInfo.onStart client, ->
      redisInfo.subscribeToStarts subClient, client, (starts) ->
        checkFirstStart starts
        done()
  
  'subscribeToStarts should callback on set of starts': (done) ->
    redisInfo.onStart client, ->
      count = 0
      redisInfo.subscribeToStarts subClient, client, (starts) ->
        return checkFirstStart starts unless count++
        starts.length.should.eql 2
        startId = starts[0][0]
        [startTime, startsLength] = startId.split '.'
        startsLength.should.eql '1'
        done()
      redisInfo.onStart client
