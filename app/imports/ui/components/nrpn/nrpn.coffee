import _ from 'lodash'
import './nrpn.html'
import WebMidi from 'webmidi'

SELECTED_OUTPUT = null
SELECTED_INPUT  = null

select_output = ( id ) ->
  SELECTED_OUTPUT = WebMidi.getOutputById id

  console.log 'selected out ->', SELECTED_OUTPUT

select_input = ( id ) ->

  SELECTED_INPUT = WebMidi.getInputById id

  console.log 'selected in ->', SELECTED_INPUT

send_value = ( value ) ->
  value_MSB = value / 128
  value_LSB = value % 128

  console.log ''
  console.log "sending #{value} to #{SELECTED_OUTPUT.name}"
  console.log 'MSB -> ', value_MSB
  console.log 'LSB -> ', value_LSB

  SELECTED_OUTPUT.setNonRegisteredParameter [18, 0], [ value_MSB, value_LSB], 1

send_random_value = ( min = 0, max = 4096 ) ->
  random = Math.floor(Math.random() * (max - min + 1)) + min

  send_value random

Template.nrpn.onCreated ->

  @inputs  = new ReactiveVar([])
  @outputs = new ReactiveVar([])

  self = @

  console.log 's i->', Session.get 'input'
  console.log 's o->', Session.get 'output'

  refresh_devices = ->

    console.info 'refreshing devices'

    self.inputs.set  WebMidi.inputs
    self.outputs.set WebMidi.outputs

  refresh_devices = _.debounce refresh_devices, 200

  WebMidi.enable ( err ) ->

    if (err)
      return console.log("WebMidi could not be enabled.", err)

    #  - it seems connected and disconnected are called once per input/output
    #  - we need to call "refresh_devices" every time
    #  - hence why we debounced it
    WebMidi.addListener 'connected'   , refresh_devices
    WebMidi.addListener 'disconnected', refresh_devices

    refresh_devices()

    # Select I/O based on session
    # TODO:
    #  - Make Session persistent ( cookies and/or mongodb )
    self.autorun ->

      if Session.get 'input'
        select_input Session.get('input')

      if Session.get 'output'
        select_output Session.get('output')

Template.nrpn.helpers

  inputs: ->
    Template.instance().inputs.get()

  selected_input: ->
    Session.get 'input'

  is_selected: ( key, value ) ->
    Session.get( key ) is value

  outputs: ->
    Template.instance().outputs.get()

  selected_output: ->
    Session.get 'output'

Template.nrpn.events

  'change select': (event, instance) ->

    $dom = $ event.currentTarget

    if $dom.hasClass 'input'

      Session.set 'input', $dom.val()

    if $dom.hasClass 'output'

      Session.set 'output', $dom.val()

  'click button.random': (event, instance) ->

    send_random_value()

  'click button.sh': (event, instance) ->

    setInterval send_random_value, 250
