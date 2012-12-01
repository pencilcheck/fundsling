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
            if data[0] == 0
                $('#motivation-speech').text('put yourself first in line!')
            else if data[0] < 4
                $('#motivation-speech').text('join the line right now!')
            else if data[0] < 9
                $('#motivation-speech').text('we are so close, only need a few more')
            else if data[0] == 10
                $('#motivation-speech').text('thanks for everyone who have clicked on the button, nothing will be shipped, it is a scam! Muhahahaha')
            setTimeout(poll, 1000)
        error: (XMLHttpRequest, textStatus, errorThrown) ->
            console.log 'error', textStatus, errorThrown
            setTimeout(poll, 2000)
    )

poll()
