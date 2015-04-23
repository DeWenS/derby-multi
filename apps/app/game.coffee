app = require './index'

app.get '/game/:gameId', (page, model, params) ->
  gameId = params.gameId

  model.subscribe 'games.' + gameId, ->
    game = model.get 'games.' + gameId

    if game.finished
      rounds = game.rounds
#      console.log rounds
      result = []

      # Header
      line = ['-']
      for i in [1..8]
        line.push 'Round ' + i
      line.push 'Total'
      result.push line

      #Quantity
      line = ['Quantity']
      for i in [1..9]
        line.push ' '
      result.push line

      # User answers
      for pkey of game.players
        line = [pkey]
        for rkey of rounds
          line.push rounds[rkey][pkey]
        line.push ' '
        result.push line

      # empty
      emptyLine = []
      for i in [1..10]
        emptyLine.push ' '
      result.push emptyLine

      # price
      line = ['Price']
      price = []
      for i in [1..8]
        sum = 0;
        for k of rounds[i]
          sum += rounds[i][k];

        line.push (45 - 0.2 * sum)
        price.push (45 - 0.2 * sum)
      line.push ' '
      result.push line

      # empty
      result.push emptyLine

      #profit title
      line = ['Profit']
      for i in [1..8]
        line.push ' '
      line.push 'Total Profit'
      result.push line

      #profit
      for pkey of game.players
        line = [pkey]
        totalProfit = 0
        for round in [1..8]
          profitValue = (rounds[round][pkey] * (price[round-1] - 5))
          line.push profitValue
          totalProfit += profitValue
        line.push totalProfit
        result.push line

      model.set '_page.result', result


    if !game
      page.redirect '/'

    usersInGame = model.query 'users', 'games.' + params.gameId + '.userIds'
    userId = model.get '_session.userId'
    user = model.at 'users.' + userId
    model.subscribe usersInGame, user, ->
      model.ref '_page.user', user
      model.ref '_page.userId', userId
      model.ref '_page.game', 'games.' + gameId
      model.ref '_page.players', 'games.' + params.gameId + '.players'
      model.ref '_page.rounds', 'games.' + params.gameId + '.rounds'
      model.ref '_page.currentRound', 'games.' + params.gameId + '.currentRound'
      model.ref '_page.player', 'games.' + params.gameId + '.players.' + userId

#      if (game.userIds.length >= 3) && !(userId in game.userIds)
#        alert 'hete'
#        page.redirect '/'

      if (!model.get '_page.player') && (game.userIds.length < 3)
        model.add '_page.players', {'id': userId}
        model.push '_page.game.userIds', userId
        players = model.get '_page.game.userIds'
        if players.length >= 3
          model.set '_page.game.ready', true
  page.render 'game'


