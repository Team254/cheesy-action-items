$(function(){
    $('.typeahead').typeahead();
    $('#due-date-picker').datepicker();

    $("#future-one-week").click(function(event) {
        var nextWeek = new Date();
        nextWeek.setDate(nextWeek.getDate() + 7);
        var year = nextWeek.getFullYear();
        var month = nextWeek.getMonth() + 1;
        var day = nextWeek.getDate();

        if (month.toString().length < 2) {
            month = "0" + month.toString();
        }
        if (day.toString().length < 2) {
            day = "0" + month.toString();
        }

        $("#due-date-picker").val(year + "-" + month + "-" + day);
    });
});


