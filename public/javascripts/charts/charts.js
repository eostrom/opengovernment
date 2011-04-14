$(document).ready(function() {
  var formatNumber = function(n, c, d, t){
    var c = isNaN(c = Math.abs(c)) ? 0 : c,
      d = d == undefined ? "." : d,
      t = t == undefined ? "," : t,
      s = n < 0 ? "-" : "",
      i = parseInt(n = Math.abs(+n || 0).toFixed(c)) + "",
      j = (j = i.length) > 3 ? j % 3 : 0;

   return s + (j ? i.substr(0, j) + t : "") +
        i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) +
        (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
  };

  var points = $.map(people_json, function(person) {
    var cities = $.map(person.addresses, function(address) {
      if (address.votesmart_type == 'District') {
        return address.city;
      }
    }).sort();
    if (!cities[0]) { cities.shift(); }
    if (cities.length > 0) { 
      person.district_address_cities = cities.join(', '); 
    }

    var color = {
      Democrat: '#0000FF',
      Republican: '#FF0000',
      Multiple: '#CC00CC'
    }[person.party] || '#888888'

    return {
      x: person.contributions_sum,
      y: person.contributions_avg,
      name: person.full_name,
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
        mouseOver: function(event) {
          $('#person').html(
            JST['person']({
              person: person
            })
          );
        },
        click: function() {
          window.location = person.permalink;
        }
      }
    };
  });

  var chart = new Highcharts.Chart({
    title: {
      text: null
    },
    chart: {
      renderTo: 'contributions_chart',
      defaultSeriesType: 'scatter'
    },
    legend: {
      enabled: false
    },
    series: [
      {
        data: points
      }
    ],
    tooltip: {
      formatter: function(i) {
        var point = this.point;
        var count = Math.round(point.x / point.y);

        return '<b>' + point.name + '</b>: ' +
          '$' + formatNumber(point.x, 0) +
          ' from ' + formatNumber(count) + ' contributors';
      }
    },
    xAxis: {
      title: {
        text: 'total contributed ($)'
      },
      min: 0
    },
    yAxis: {
      title: {
        text: 'average contribution ($)'
      },
      min: 0
    }
  });
});
