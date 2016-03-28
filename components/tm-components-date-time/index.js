
function DateTime () {}

DateTime.locale = {
  am: "AM",
  pm: "PM",
  months: {
    full: [
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
    ],
    shrt: [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ]
  },
  days: {
    full: [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ],
    shrt: [
      "Sun",
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat"
    ]
  }
};

function Transformer ( date, locale ) {
  locale = locale;
  day = date.getDay();
  dayi = date.getDate();
  month = date.getMonth();
  year = date.getFullYear();
  hours = date.getHours();
  hours12 = hours % 12;
  if ( hours12 == 0 ) hours12 = 12;
  minutes = date.getMinutes();
  seconds = date.getSeconds();
  ampm = hours >= 12 ? locale.pm : locale.am;

  this.map = {
    "Y": year,
    "y": String(year).slice(2, 4),
    "F": locale.months.full[month],
    "M": locale.months.shrt[month],
    "n": month + 1,
    "m": ("0" + (month + 1)).slice(-2),
    "d": ("0" + dayi).slice(-2),
    "j": dayi,
    "D": locale.days.shrt[day],
    "l": locale.days.full[day],
    "a": ampm.toLowerCase(),
    "A": ampm,
    "g": hours12,
    "G": hours,
    "h": ("0" + hours12).slice(-2),
    "H": ("0" + hours).slice(-2),
    "i": ("0" + minutes).slice(-2),
    "I": minutes,
    "s": ("0" + seconds).slice(-2),
    "S": seconds
  };
};

Transformer.prototype.transform = function ( character ) {
  return this.map[character] != undefined ? this.map[character] : character;
};

DateTime.format = function ( format, date, locale ) {
  format = format || "F j, Y";
  date = date || new Date();
  locale = locale || DateTime.locale;
  transformer = new Transformer(date, locale);
  str = "";

  for ( var i = 0; i < format.length; i++ ) {
    str += transformer.transform(format.charAt(i));
  }

  return str;
};

DateTime.parseShortYear = function ( year ) {
  return parseInt(year.toString().match(/\d{2}$/)[0]);
};

// SEE http://stackoverflow.com/questions/4060004/calculate-age-in-javascript/7091965#7091965
DateTime.getAge = function ( birthDate ) {
  var today = new Date();
  var age = today.getFullYear() - birthDate.getFullYear();
  var m = today.getMonth() - birthDate.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
      age--;
  }
  return age;
}

DateTime.isorx = /^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/

// Checks a string to see if it follows the ISO standard. Useful for parsing
// dates from JSON.
DateTime.isIsoString = function isIsoDate (str) {
  return DateTime.isorx.test(str)
}

module.exports = DateTime;
