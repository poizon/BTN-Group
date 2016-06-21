/*
 * version: jvalidate 3.1.1 05.11.2013
 * author: hmelii
 * email: anufry@inbox.ru
 */


(function ($) {

    var methods = {

        init: function (options) {

            var settings = $.extend({
                regexpTel: /^((8|\+7)[\- ]?)?(\(?\d{3}\)?[\- ]?)?[\d\- ]{7,10}$/,
                regexpEmail: /^[A-Za-zÀ-ßà-ÿ¸¨0-9](([_\.\-]?[a-zA-ZÀ-ßà-ÿ¸¨0-9]+)*)@([A-Za-zÀ-ßà-ÿ¸¨0-9]+)(([\.\-]?[a-zA-ZÀ-ßà-ÿ¸¨0-9]+)*)\.([A-Za-zÀ-ßà-ÿ¸¨])+$/,
                regexpUrl: /^(https?:\/\/)?([\w\.]+)\.([a-z]{2,6}\.?)(\/[\w\.]*)*\/?$/,
                errorMessageEmpty: 'invalid',
                correctMessage: 'valid',
                errorMessageCorrect: 'invalid',
                classFieldError: 'invalid',
                classFieldCorrect: 'valid',
                classInvalidMessage : 'invalid_message',
                classValidMessage : 'valid_message'
            }, options || {});

            return this.each(function (index, element) {


                var $ele = $(element);

                var data = $ele.data('jvalidate');

                if (!data) {

                    $ele.attr('novalidate', 'novalidate');

                    $ele.data('jvalidate', {
                        'form': $ele,
                        'settings': settings,
                        'errors': 0
                    });


                    $ele.on('submit.jvalidate',function (event) {

                        $ele.jvalidate('submit');

                        data = $ele.data('jvalidate');

                        if (data.errors) {
                            event.preventDefault();
                        }

                    }).on('reset.jvalidate', function (event) {

                        $ele.jvalidate('reset');

                    });

                    data = $ele.data('jvalidate');


                    $ele.on('keyup.jvalidate change.jvalidate click.jvalidate', '.'+data.settings.classFieldError+', .'+data.settings.classFieldCorrect, function () {
                        $(this).jvalidate('validate').focus();
                    });

                }

            });
        },

        submit: function () {

            return this.each(function (index, element) {
                var $ele = $(element);
                var data = $ele.data('jvalidate');

                if (!data) {
                    $ele.jvalidate('init');
                    data = $ele.data('jvalidate');
                }

                data.form.data('jvalidate').errors = 0;

                var $fields = $ele.find('[required]:visible,[type=email]:not([required]),[type=tel]:not([required]),[type=url]:not([required]),[pattern]:not([required])');

                $fields.data('jvalidate', {
                    'form': $ele
                });

                $fields.jvalidate('validate');

                $ele.find('.'+data.settings.classFieldError).eq(0).focus();


            });
        },

        reset: function () {

            return this.each(function (index, element) {
                var $ele = $(element);
                var data = $ele.data('jvalidate');

                if (!data) {
                    $ele.jvalidate('init');
                    data = $ele.data('jvalidate');
                }

                data.form.data('jvalidate').errors = 0;

                var $fields = $ele.find('[required]:visible');

                $fields.jvalidate('removeErrorMessage');

                $fields.jvalidate('removeCorrectMessage');


            });
        },

        validate: function () {

            return this.each(function (index, element) {

                var $ele = $(element);

                var $form = $ele.data('jvalidate').form;

                var data = $form.data('jvalidate');

                var eleValue = $ele.val();

                var elePlaceholder = $ele.attr('placeholder');

                var eleType = $ele.attr('type');

                var eleRequired = $ele.attr('required');

                var elePattern = $ele.attr('pattern') || ( eleType=='tel' ? data.settings.regexpTel : eleType=='email' ? data.settings.regexpEmail : eleType=='url' ? data.settings.regexpUrl : false);

                $ele.jvalidate('removeErrorMessage');

                $ele.jvalidate('removeCorrectMessage');

                if ((!eleValue.length || eleValue == elePlaceholder) && eleType != 'checkbox' && eleType != 'radio' && eleRequired) {
                    $ele.jvalidate('addErrorMessageEmpty');
                    data.errors += 1;
                    return;
                } else if (eleValue.length && elePattern && !eleValue.match(elePattern)) {
                    $ele.jvalidate('addErrorMessageCorrect');
                    data.errors += 1;
                    return;
                } else if ( eleType == 'checkbox' && !$ele.prop('checked')) {
                    $ele.jvalidate('addErrorMessageEmpty');
                    data.errors += 1;
                    return;
                } else if (eleType == 'radio' && !$('[name='+$ele.attr('name')+']:checked').length) {
                    $ele.jvalidate('addErrorMessageEmpty');
                    data.errors += 1;
                    return;
                } else if (eleValue.length && eleType == 'password' && $ele.attr('data-password') && $('#' + $ele.attr('data-password')).val() != eleValue) {
                    $ele.jvalidate('addErrorMessageCorrect');
                    data.errors += 1;
                    return;
                } else {
                    $ele.jvalidate('addCorrectMessage');
                }

                $form.data('jvalidate', data);

            });
        },

        addErrorMessageEmpty: function () {

            return this.each(function (index, element) {

                var $ele = $(element);

                var $form = $ele.data('jvalidate').form;

                var data = $form.data('jvalidate');

                var errorMessageEmpty = $ele.attr('data-error-message-empty') || data.settings.errorMessageEmpty;

                $ele.addClass(data.settings.classFieldError);

                var $span = $('.' + $ele.attr('id') + '__'+data.settings.classInvalidMessage);

                if ($span.length) {

                    $span.html(errorMessageEmpty).removeClass('hidden');

                } else {
                    if (!$ele.parents('.parent_field:first').length) {
                        $ele.wrap('<span class="parent_field" style="width: '+$ele.outerWidth(true)+'px" />');
                    }

                    $ele.after('<span class="'+data.settings.classInvalidMessage+'">' + errorMessageEmpty + '</span>');


                }

            });
        },

        addErrorMessageCorrect: function () {
            return this.each(function (index, element) {

                var $ele = $(element);

                var $form = $ele.data('jvalidate').form;

                var data = $form.data('jvalidate');

                var errorMessageCorrect = $ele.attr('data-error-message-correct') || data.settings.errorMessageCorrect;

                $ele.addClass(data.settings.classFieldError);

                var $span = $('.' + $ele.attr('id') + '__' + data.settings.classInvalidMessage);

                if ($span.length) {

                    $span.html(errorMessageCorrect).removeClass('hidden');

                } else {
                    if (!$ele.parents('.parent_field:first').length) {

                        $ele.wrap('<span class="parent_field" style="width: '+$ele.outerWidth(true)+'px" />');
                    }
                    $ele.after('<span class="'+data.settings.classInvalidMessage+'">' + errorMessageCorrect + '</span>');

                }
            });
        },

        removeErrorMessage: function () {

            return this.each(function (index, element) {
                var $ele = $(element);

                var $form = $ele.data('jvalidate').form;

                var data = $form.data('jvalidate');

                if (!$ele.hasClass(data.settings.classFieldError)) {
                    return;
                }

                $ele.removeClass(data.settings.classFieldError);

                var $span = $('.' + $ele.attr('id') + '__'+data.settings.classInvalidMessage);

                if ($span.length) {

                    $span.html('').addClass('hidden');

                } else {
                    $ele.siblings('.'+data.settings.classInvalidMessage).remove();
                }

            });

        },

        addCorrectMessage: function () {
            return this.each(function (index, element) {

                var $ele = $(element);

                var $form = $ele.data('jvalidate').form;

                var data = $form.data('jvalidate');

                var correctMessage = $ele.attr('data-correct-message') || data.settings.correctMessage;

                $ele.addClass(data.settings.classFieldCorrect);

                var $span = $('.' + $ele.attr('id') + '__'+data.settings.classValidMessage);

                if ($span.length) {

                    $span.html(correctMessage).removeClass('hidden');

                } else {
                    if (!$ele.parents('.parent_field:first').length) {
                        $ele.wrap('<span class="parent_field" style="width: '+$ele.outerWidth(true)+'px" />');
                    }
                    $ele.after('<span class="'+data.settings.classValidMessage+'">' + correctMessage + '</span>');

                }
            });
        },

        removeCorrectMessage: function () {
            return this.each(function (index, element) {

                var $ele = $(element);

                var $form = $ele.data('jvalidate').form;

                var data = $form.data('jvalidate');

                if (!$ele.hasClass(data.settings.classFieldCorrect)) {
                    return;
                }

                $ele.removeClass(data.settings.classFieldCorrect);

                var $span = $('.' + $ele.attr('id') + '__'+data.settings.classValidMessage);

                if ($span.length) {
                    $span.html('').addClass('hidden');
                } else {
                    $ele.siblings('.'+data.settings.classValidMessage).remove();
                }
            });
        }

    };

    $.fn.jvalidate = function (method) {

        if (methods[method]) {

            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));

        } else if (typeof method === 'object' || !method) {

            return methods.init.apply(this, arguments);

        } else {

            $.error('Ìåòîä ñ èìåíåì ' + method + ' íå ñóùåñòâóåò äëÿ validate');

        }

    };


    $(function(){
        $('.js-validate').jvalidate();
    })








})(jQuery);