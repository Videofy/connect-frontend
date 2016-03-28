
months = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
]

module.exports =
  formatDate: (date) ->
    return "" unless date?
    stringDate = months[date.getMonth()] + ' ' +
      date.getDate() + ', ' +
      date.getFullYear()
    stringDate

  formattedDate: (attr) ->
    date = @get attr
    return "" unless date?
    date = new Date(date) unless typeof date is Date
    module.exports.formatDate(date)

  getReleaseDate: ->
    date = @get("releaseDate")
    if not date
      date = new Date(@get("released"))
      if not isNaN(date.getTime())
        date = date.toString()
        @set("releaseDate", date)
      else
        date = ""
    date

