derby = require 'derby'

app = module.exports = derby.createApp 'app', __filename

app.use require 'derby-router'
app.use require 'derby-debug'
app.serverUse module, 'derby-jade' , {coffee: true}
app.serverUse module, 'derby-stylus'

app.loadViews __dirname + '/views'
app.loadStyles __dirname + '/styles'

require './game'

app.proto.deleteGames = ->
  games = @model.get 'games'
  for key of games
    @model.del "games.#{key}"

app.proto.setUsername = ->
  userId = @model.get '_session.userId'
  username = @model.get '_page.username'
  if username?
    username = username.trim()
  if username
    user = @model.at 'users.' + userId
    @model.fetch user , ->
      user.set {'name': username}
  else
    alert 'Name cannot be empty'

app.proto.setAnswer = ->
  answer = @model.get '_page.answer'
  game = @model.get '_page.game'
  user = @model.get '_page.user'
  userId = @model.get '_session.userId'
  currentRound = @model.get '_page.currentRound'
  rounds = @model.get '_page.rounds'
  unless answer?
    answer = NaN
  answer = parseInt(answer)
  if isNaN(answer)
    alert "Answer must be a number"
  else
    if answer < 0 || answer > 75
      alert "Number should be in range 0-75"
    else
      @model.set '_page.rounds.' + currentRound + '.' + userId, answer
      if Object.keys(game.rounds[game.currentRound]).length >= 3
        newRound = @model.increment '_page.game.currentRound'
        if newRound > 8
          @model.set '_page.game.finished', true
      @model.del '_page.answer'

app.proto.startGame = ->
  gameId = @model.get '_page.game.id'
  @model.set 'games.' + gameId + '.started', true
  @model.set 'games.' + gameId + '.currentRound', 1


global.app = app


app.get '/', (page, model, params) ->
  userId = model.get '_session.userId'
  user = model.at 'users.' + userId
  model.subscribe 'games', user, ->
    model.ref('_page.user', user)
    model.at('games').filter().ref('_page.games')
    page.render 'home'

app.post '/create_game', (page, model, params) ->
  model.add 'games', {
    name: params.body.name,
    players: {},
    userIds: [],
    rounds: {},
    ready: false,
    started: false,
    finished: false,
    currentRound: 1
  }, -> page.redirect '/'

