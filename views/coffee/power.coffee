jQuery ->
    $('form#add-product-form').ajaxForm
        success: (data) =>
            data = JSON.parse data
            $('#public_url').html("<a href='/?#{data.public_link_id}'>http://power.com/?#{data.public_link_id}</a>")
            $('.result').html("Your Power! page: <a href='/?#{data.public_link_id}'>http://power.com/?#{data.public_link_id}</a>")
            $('#submitModal').reveal(animation: 'fade')
        error: (XMLHttpRequest, textStatus, errorThrown) ->
            alert ["/icecream/products", textStatus, textStatus, errorThrown]

