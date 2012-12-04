poll = (url, type, success, error, debug) ->
    console.log "polling for #{url}..."
    $.ajax(
        type: type
        url: url
        async: true
        cache: false
        timeout: 50000

        success: (data) ->
            data = JSON.parse data
            if debug
                console.log data
            success(data)
            setTimeout(poll, 1000)
        error: (XMLHttpRequest, textStatus, errorThrown) ->
            console.log 'error', textStatus, errorThrown
            error(XMLHttpRequest, textStatus, errorThrown)
            setTimeout(poll, 2000)
    )

###
            $('#number-of-pepsi').text(data[0])
            $('#leftovers-of-pepsi').text(data[1])
            if data[0] == 0
                $('#motivation-speech').text('put yourself first in line!')
            else if data[0] < 4
                $('#motivation-speech').text('join the line right now!')
            else if data[0] < 9
                $('#motivation-speech').text('we are so close, only need a few more')
            else if data[0] == 10
                $('#motivation-speech').text('thanks for everyone who have clicked on the button, nothing will be shipped, it is a scam! Muhahahaha')
###
