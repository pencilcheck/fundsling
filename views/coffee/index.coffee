poll = ->
    console.log 'polling...'
    $.ajax(
        type: "GET"
        url: "/number"
        async: true
        cache: false
        timeout: 50000

        success: (data) ->
            data = JSON.parse(data)
            console.log data
            $('#number-of-pepsi').text(data[0])
            setTimeout(poll, 1000)
        error: (XMLHttpRequest, textStatus, errorThrown) ->
            console.log 'error', textStatus, errorThrown
            setTimeout(poll, 2000)
    )

poll()
