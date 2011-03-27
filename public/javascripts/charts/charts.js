$(document).ready(function() {
  var formatMoney = function(n, c, d, t){
    var c = isNaN(c = Math.abs(c)) ? 2 : c,
      d = d == undefined ? "." : d,
      t = t == undefined ? "," : t,
      s = n < 0 ? "-" : "",
      i = parseInt(n = Math.abs(+n || 0).toFixed(c)) + "",
      j = (j = i.length) > 3 ? j % 3 : 0;

   return s + (j ? i.substr(0, j) + t : "") +
        i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) +
        (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
  };

  var points = $.map(contributions, function(person) {
    var color = {
      Democrat: '#0000FF',
      Republican: '#FF0000',
      Multiple: '#CC00CC'
    }[person.party] || '#888888'

    return {
      x: person.contributions_count,
      y: person.contributions_sum,
      name: person.first_name + ' ' + person.last_name,
      color: color,
      marker: {
        fillColor: color,
        states: {
          hover: {
            fillColor: color
          }
        }
      },
      events: {
        click: function() {
          window.location = person.permalink;
        }
      }
    };
  });

  var chart = new Highcharts.Chart({
    title: {
      text: 'Campaign Contributions'
    },
    chart: {
      renderTo: 'contributions_chart',
      defaultSeriesType: 'scatter'
    },

    series: [
      {
        data: points
      }
    ],
    tooltip: {
      formatter: function(i) {
        var point = this.point;

        return '<b>' + point.name + '</b>: ' +
          point.x + ' contributions, $' + formatMoney(point.y, 0);
      }
    },
    xAxis: {
      title: {
        text: '# of contributions'
      },
      min: 0
    },
    yAxis: {
      title: {
        text: 'total contributed ($)'
      },
      min: 0
    }
  });
});
