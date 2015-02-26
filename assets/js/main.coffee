vimeo_ready = (pid) ->
    fp = Froogaloop(pid)
    fp.addEvent 'pause', vimeo_paused
    fp.addEvent 'finish', vimeo_finished
    fp.api 'play'

vimeo_paused = ->
    jQuery("#overlay").fadeIn 800

vimeo_finished = ->
    $("#overlay").show()

$(document).ready ->

    $("#overlay").bind 'click', ->
        $(this).fadeOut 800
        fp = Froogaloop(($("#video")[0]))
        fp.addEvent 'ready', vimeo_ready