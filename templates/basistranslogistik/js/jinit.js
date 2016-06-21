var html = document.documentElement; // html element
var path = ''; // location scripts and styles

Modernizr.load([
    {   // if not supported attribute placeholder - load fix script
        test : Modernizr.input.placeholder,
        nope : [ path + 'js/jplaceholder.js'],
        callback : function() {

            $('[placeholder]').jplaceholder();
        }
    }
]);

$(function() {

    initFooter();

    $('.js-carousel_1').each(function() {
        initCarousel1(this);
    });

    $('.js-carousel_2').each(function(event) {
        initcarousel2(this);
    });

    $('.js-carousel_3').each(function() {
        initCarousel3(this);
    });

    $('.js-carousel_4').each(function() {
        initCarousel4(this);
    });

    if($('.jqzoom').length){
        init_jqzoom()
    }


});

function init_jqzoom() {
    $('.jqzoom').jqzoom({
        zoomType: 'reverse',
        lens:true,
        preloadImages: false,
        alwaysOn:false,
        zoomWidth: 350,
        zoomHeight: 350
    });



}

function initCarousel4(obj) {
    var $car = $(obj);
    var $list = $car.find('>.in>.list');
    var $items = $list.find('.item');
    var $prev = $car.find('.prev');
    var $next = $car.find('.next');
    var i = 0;
    var l = $items.length - 1;
    var t;
    var anime = false;

    if (l<1) {
        $list.css('width','auto');
        $prev.hide();
        $next.hide();
        return;
    }




    function animeLeft(index) {
        i>0?i--:i=l;
        anime = true;
        $items = $list.find('>.item');
        var $last = $items.filter(':last');
        $list.prepend($last).css('marginLeft','-201px');
        setTimeout(function() {
            $list.addClass('animate');
            setTimeout(function() {
                $list.css('marginLeft', 0);
                setTimeout(function() {
                    $list.removeClass('animate');
                    setTimeout(function() {
                        if (index==i) {

                            anime = false;
                        } else {
                            animeLeft(index);
                        }
                    }, 25);
                }, 1000);
            },25);
        }, 25);
    }

    $prev.click(function(event) {
        event.preventDefault();
        clearInterval(t);
        if (anime) {
            return;
        }
        var index = i;
        index>0?index--:index=l;
        animeLeft(index);
    });

    $next.click(function(event) {
        event.preventDefault();
        clearInterval(t);
        if (anime) {
            return;
        }
        var index = i;
        index<l?index++:index=0;
        animeRight(index);
    });

    function animeRight(index) {
        i<l?i++:i=0;
        anime = true;
        $items = $list.find('>.item');
        var $first = $items.filter(':first');
        $list.addClass('animate');
        setTimeout(function() {
            $list.css('marginLeft','-201px');


            setTimeout(function() {
                $list.removeClass('animate');
                setTimeout(function() {
                    $list.css('marginLeft', 0).append($first);
                    setTimeout(function() {
                        if (index==i) {

                            anime = false;
                        } else {
                            animeRight(index);
                        }
                    }, 25);
                },25);
            }, 1000);

        }, 25);
    }

    function autoPlay() {
        clearInterval(t);
        t = setInterval(function() {
            if (anime) {
                return;
            }
            var index = i;
            index<l?index++:index=0;
            animeRight(index)
        }, 6000)
    }
    autoPlay();

    $car.on({
        'mouseenter': function() {
            clearInterval(t);
        },
        'mouseleave': autoPlay
    })

}

function initCarousel3(obj) {
    var $car = $(obj);
    var $list = $car.find('>.in>.list');
    var $items = $list.find('.item');
    var $prev = $car.find('.prev');
    var $next = $car.find('.next');
    var i = 0;
    var l = $items.length - 1;
    var t;
    var anime = false;
    var $tabs = $car.find('.tabs .list');
    var li = '';

    if (l<1) {
        $list.css('width','auto');
        $prev.hide();
        $next.hide();
        return;
    }

    for (var j=0; j<=l; j++) {
        li += '<li class="item"><a class="link'+(j==0?' active':'')+'" data-index="'+j+'" /></li>';
    }

    $tabs.html(li);

    var $links = $tabs.find('.link');

    $tabs.on('click', '.link', function(event) {
        event.preventDefault();
        clearInterval(t);
        var index = parseInt($(this).attr('data-index'));
        if (index<i) {
            animeLeft(index);

        } else if (index>i) {
            animeRight(index);
        }

    });


    function animeLeft(index) {
        $links.eq(i).removeClass('active');
        i>0?i--:i=l;
        $links.eq(i).addClass('active');
        anime = true;
        $items = $list.find('>.item');
        var $last = $items.filter(':last');
        $list.prepend($last).css('marginLeft','-331px');
        setTimeout(function() {
            $list.addClass('animate');
            setTimeout(function() {
                $list.css('marginLeft', 0);
                setTimeout(function() {
                    $list.removeClass('animate');
                    setTimeout(function() {
                        if (index==i) {

                            anime = false;
                        } else {
                            animeLeft(index);
                        }
                    }, 25);
                }, 1000);
            },25);
        }, 25);
    }

    $prev.click(function(event) {
        event.preventDefault();
        clearInterval(t);
        if (anime) {
            return;
        }
        var index = i;
        index>0?index--:index=l;
        animeLeft(index);
    });

    $next.click(function(event) {
        event.preventDefault();
        clearInterval(t);
        if (anime) {
            return;
        }
        var index = i;
        index<l?index++:index=0;
        animeRight(index);
    });

    function animeRight(index) {
        $links.eq(i).removeClass('active');
        i<l?i++:i=0;
        $links.eq(i).addClass('active');
        anime = true;
        $items = $list.find('>.item');
        var $first = $items.filter(':first');
        $list.addClass('animate');
        setTimeout(function() {
            $list.css('marginLeft','-331px');


            setTimeout(function() {
                $list.removeClass('animate');
                setTimeout(function() {
                    $list.css('marginLeft', 0).append($first);
                    setTimeout(function() {
                        if (index==i) {

                            anime = false;
                        } else {
                            animeRight(index);
                        }
                    }, 25);
                },25);
            }, 1000);

        }, 25);
    }

    function autoPlay() {
        clearInterval(t);
        t = setInterval(function() {
            if (anime) {
                return;
            }
            var index = i;
            index<l?index++:index=0;
            animeRight(index)
        }, 6000)
    }
    autoPlay();

    $car.on({
        'mouseenter': function() {
            clearInterval(t);
        },
        'mouseleave': autoPlay
    })

}

function initcarousel2(obj) {
    var $car = $(obj);
    var $list = $car.find('.list');
    var $items = $car.find('.item');
    var $prev = $car.find('.prev');
    var $next = $car.find('.next');
    var i = 0;
    var l = $items.length - 5;
    var t;
    var anime = false;

    if (l<1) {
        $list.css('width','auto');
        $prev.hide();
        $next.hide();
        return;
    }




    function animeLeft(index) {
        i>0?i--:i=l;
        anime = true;
        $items = $list.find('>.item');
        var $last = $items.filter(':last');
        $list.prepend($last).css('marginLeft','-201px');
        setTimeout(function() {
            $list.addClass('animate');
            setTimeout(function() {
                $list.css('marginLeft', 0);
                setTimeout(function() {
                    $list.removeClass('animate');
                    setTimeout(function() {
                        if (index==i) {

                            anime = false;
                        } else {
                            animeLeft(index);
                        }
                    }, 25);
                }, 1000);
            },25);
        }, 25);
    }

    $prev.click(function(event) {
        event.preventDefault();
        clearInterval(t);
        if (anime) {
            return;
        }
        var index = i;
        index>0?index--:index=l;
        animeLeft(index);
    });

    $next.click(function(event) {
        event.preventDefault();
        clearInterval(t);
        if (anime) {
            return;
        }
        var index = i;
        index<l?index++:index=0;
        animeRight(index);
    });

    function animeRight(index) {

        i<l?i++:i=0;
        anime = true;
        $items = $list.find('>.item');
        var $first = $items.filter(':first');
        $list.addClass('animate');
        setTimeout(function() {
            $list.css('marginLeft','-201px');


            setTimeout(function() {
                $list.removeClass('animate');
                setTimeout(function() {
                    $list.css('marginLeft', 0).append($first);
                    setTimeout(function() {
                        if (index==i) {

                            anime = false;
                        } else {
                            animeRight(index);
                        }
                    }, 25);
                },25);
            }, 1000);

        }, 25);
    }

    function autoPlay() {
        clearInterval(t);
        t = setInterval(function() {
            if (anime) {
                return;
            }
            var index = i;
            index<l?index++:index=0;
            animeRight(index)
        }, 6000)
    }
    autoPlay();

    $car.on({
        'mouseenter': function() {
            clearInterval(t);
        },
        'mouseleave': autoPlay
    })
}

function initCarousel1(obj) {
    var $car = $(obj);
    var $items = $car.find('.item');
    var currentItemIndex = 0;
    var lastItemIndex = $items.length - 1;
    var $tabs = $car.find('.tabs .list');
    var tabsList = '';
    var autoPlayInterval;
    var TIME = 6;

    if (lastItemIndex < 1) {
        return;
    }

    for (var j=0; j<= lastItemIndex; j++) {
        tabsList += '<li class="item"><a class="link'+(j==0?' active':'')+'" data-index="'+j+'" /></li>';
    }

    $tabs.html(tabsList);

    var $links = $tabs.find('.link');

    $tabs.on('click', '.link', function(event) {
        event.preventDefault();
        clearInterval(autoPlayInterval);
        changeCurrentItem(parseInt($(this).attr('data-index')));
    });

    var changeCurrentItem = function(index) {

        $links.eq(currentItemIndex).removeClass('active');
        $items.eq(currentItemIndex).removeClass('active');
        currentItemIndex = index;
        $links.eq(currentItemIndex).addClass('active');
        $items.eq(currentItemIndex).addClass('active');

    };

    var autoPlay = function() {
        clearInterval(autoPlayInterval);
        autoPlayInterval = setInterval(function() {
            var index = currentItemIndex;
            index < lastItemIndex ? index++ : index = 0;
            changeCurrentItem(index);
        }, TIME * 1000);
    };
    autoPlay();

}

function initFooter() {
    var $inner = $('.inner');
    var $footer = $('.footer');
    $inner.css('marginBottom',$footer.outerHeight()+'px');
}




		