document.addEventListener('turbolinks:load', function(){
  var $dataElement  = $('#issues-summary-data'),
      $chartElement = $('#issue-chart');

  if ($dataElement.length && $chartElement.find('svg').length == 0) {
    var divWidth = $('#issue-chart').width();
    var leftMargin = (divWidth - 400)/3

    var margin = {top: 20, right: 20, bottom: 30, left: 40},
      width = 400 - margin.left - margin.right,
      height = 200 - margin.top - margin.bottom;

    var x = d3.scale.ordinal()
        .rangeRoundBands([0, width], .1);

    var y = d3.scale.linear()
        .range([height, 0]);

    var xAxis = d3.svg.axis()
        .scale(x)
        .tickSize(0)
        .orient('bottom');

    var yAxis = d3.svg.axis()
        .scale(y)
        .orient('left')
        .tickSize(1, 1)
        .tickFormat(d3.format('.0f'))
        .ticks(2);
        // .tickValues([1, 3, 4]);

    var svg = d3.select('#issue-chart').append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
      .append('g')
        .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

    // --------------------------------------------------------- Data variables
    var tags        = $dataElement.data('tags');
    var issuesByTag = $dataElement.data('issues-count');
    var highest     = 0;
    var data        = [];
    var x_domain    = [];

    for (var key in tags){
      issuesCount = issuesByTag[key];
      highest = issuesCount > highest ? issuesCount : highest
      data.push({letter: tags[key][0], frequency: issuesCount});
      x_domain.push(tags[key][0]);
    }
    data.push({letter: 'N/A', frequency: issuesByTag['unassigned']})
    x_domain.push('N/A');

    var highest_y = Math.max(highest, issuesByTag['unassigned']);
    // -------------------------------------------------------- /Data variables


    // x.domain(['High', 'Medium', 'Low']);
    x.domain(x_domain);

    // y.domain([0, 5]);
    y.domain([0, highest_y]);

    svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', 'translate(0,' + height + ')')
        .call(xAxis);

    // svg.append('g')
    //     .attr('class', 'y axis')
    //     .call(yAxis)

    var bars = svg.append('g');

    bars.selectAll('rect')
        .data(data)
      .enter().append('rect')
        // .attr('class', function(d){ return 'bar-' + d.letter; } )
        .attr('class', 'bar' )
        .attr('x', function(d) { return x(d.letter); })
        .attr('width', x.rangeBand())
        .attr('y', function(d) { return y(d.frequency); })
        .attr('height', function(d) { return height - y(d.frequency); });


    bars.selectAll('text')
        .data(data)
      .enter().append('text')
        .attr('x', function(d, i) { return x(d.letter) + x.rangeBand()/2; })
        .attr('y', function(d) { return y(d.frequency);})
        .attr('dy', -5)
        .attr('text-anchor', 'middle')
        .attr('class', 'counter' )
        .text(function(d) {return d.frequency;});

    var i = 0;
    for( var key in tags ){
      $($('.tick')[i]).attr('fill', tags[key][1]);
      $($('.bar')[i]).attr('fill', tags[key][1]);
      $($('.counter')[i]).attr('fill', tags[key][1]);
      i++;
    }

    $($('.tick')[tags.length]).attr('fill', '#ccc');
    $($('.bar')[tags.length]).attr('fill', '#ccc');
    $($('.counter')[tags.length]).attr('fill', '#ccc');
  }
});
