$(document).ready(function() {
  var unique = function(sortedArray) {
    var previous;

    return jQuery.grep(sortedArray,
                       function(current) {
                         if (current == previous)
                           return false;
                         previous = current;
                         return true;
                       });
  };

  $.getJSON(window.location.toString() + '.json', function(people) {
    chart.hideLoading();
    chart.addSeries({data: $.map(people, personPoint)});
  });

  function personPoint(person) {
    var cities = $.map(person.addresses, function(address) {
      if (address.votesmart_type == 'District') {
        return address.city;
      }
    }).sort();
    if (!cities[0]) { cities.shift(); }
    if (cities.length > 0) { 
      person.district_address_cities = unique(cities).join(', '); 
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
  };

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
    tooltip: {
      formatter: function(i) {
        var point = this.point;
        var count = Math.round(point.x / point.y);

        return '<b>' + point.name + '</b>: ' +
          '$' + Highcharts.numberFormat(point.x, 0) +
          ' from ' + Highcharts.numberFormat(count, 0) + ' contributors';
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

  chart.showLoading();
});