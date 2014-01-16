namespace "SensuDashboard.Models", (exports) ->

  class exports.Event extends Backbone.Model

    defaults:
      client: null
      check: null
      occurrences: 0
      action: null

    initialize: ->
      @set(id: "#{@get("client")["name"]}/#{@get("check")["name"]}")
      @setOutputIfEmpty(@get("check")["output"])
      @setStatusName(@get("check")["status"])
      @set
        url: "/events/#{@get("id")}"
        client_silence_path: "silence/#{@get("client")["name"]}"
        silence_path: "silence/#{@get("client")["name"]}/#{@get("check")["name"]}"
      @listenTo(SensuDashboard.Stashes, "reset", @setSilencing)
      @listenTo(SensuDashboard.Stashes, "add", @setSilencing)
      @listenTo(SensuDashboard.Stashes, "remove", @setSilencing)
      @setSilencing()
      console.log @

    setSilencing: ->
      silenced = false
      client_silenced = false
      silenced = true if SensuDashboard.Stashes.get(@get("silence_path"))
      client_silenced = true if SensuDashboard.Stashes.get(@get("client_silence_path"))
      if @get("silenced") != silenced || @get("client_silenced") != client_silenced
        @set
          silenced: silenced
          client_silenced: client_silenced

    setOutputIfEmpty: (output) ->
      if output == ""
        @set(output: "empty output")

    setStatusName: (status) ->
      switch status
        when 1 then @set(status_name: "warning")
        when 2 then @set(status_name: "critical")
        else @set(status_name: "unknown")

    resolve: (options = {}) =>
      @successCallback = options.success
      @errorCallback = options.error
      @destroy
        success: (model, response, opts) =>
          @successCallback.apply(this, [model, response, opts]) if @successCallback
        error: (model, xhr, opts) =>
          @errorCallback.apply(this, [model, xhr, opts]) if @errorCallback

    silence: (options = {}) =>
      @successCallback = options.success
      @errorCallback = options.error
      stash = SensuDashboard.Stashes.create({
        path: @get("silence_path")
        content: { timestamp: Math.round(new Date().getTime() / 1000) }}, {
        success: (model, response, opts) =>
          @successCallback.apply(this, [this, response]) if @successCallback
        error: (model, xhr, opts) =>
          @errorCallback.apply(this, [this, xhr, opts]) if @errorCallback})

    unsilence: (options = {}) =>
      @successCallback = options.success
      @errorCallback = options.error
      stash = SensuDashboard.Stashes.get(@get("silence_path"))
      if stash
        stash.destroy
          success: (model, response, opts) =>
            @successCallback.apply(this, [this, response, opts]) if @successCallback
          error: (model, xhr, opts) =>
            @errorCallback.apply(this, [this, xhr, opts]) if @errorCallback
      else
        @errorCallback.apply(this, [this]) if @errorCallback
