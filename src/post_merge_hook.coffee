# Description:
#   This module handles the responses to the GitHub hook when a PR gets merged.
#   When a PR gets merged on GitHub, a webook is delivered to the bot which
#   would then summarize the conflicts on all open PRs and notify if there are
#   any.
Octokat = require 'octokat'
_       = require 'underscore'
Q       = require 'q'
PrConflicts = require './pr_conflicts'

class PostMergeHook
  constructor: (@prNumber, @org, @repo) ->
    github    = new Octokat(token: process.env.GH_AUTH_TOKEN)

    @repo = github.repos(@org, @repo)

    @allPrs =
      repo.pulls.fetch({status: "open"}).then (prs) ->
        Q.all _.map(prs, (pr) -> repo.pulls(pr.number).fetch())

  unMergeablePrs: (prs) ->
    _.filter(prs, (pr) -> pr.mergeable == false)

  getClosedPrDetails: ->
    @repo.pulls(@prNumber).fetch()

  generateMessage: ->
    conflictsMessage = new PrConflicts().generateMessage()

    Q.allSettled([@getClosedPrDetails(), @allPrs, conflictsMessage])
     .then (results) =>
       closedPr = results[0].value
       allPrs   = results[1].value
       message  = results[2].value

       if @unMergeablePrs(allPrs).length
         text = "
           There are merge conflicts. Run `@bot pr conflicts` for more info
           "
         {
           text: text
           attachments: message.attachments
         }
       else
         {
           text: "No conflicts 👍🏽"
         }

module.exports = PostMergeHook
