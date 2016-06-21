
function cyr2lat(str) {

            var cyr2latChars = new Array(
                    ['а', 'a'], ['б', 'b'], ['в', 'v'], ['г', 'g'],
                    ['д', 'd'],  ['е', 'e'], ['ё', 'yo'], ['ж', 'zh'], ['з', 'z'],
                    ['и', 'i'], ['й', 'y'], ['к', 'k'], ['л', 'l'],
                    ['м', 'm'],  ['н', 'n'], ['о', 'o'], ['п', 'p'],  ['р', 'r'],
                    ['с', 's'], ['т', 't'], ['у', 'u'], ['ф', 'f'],
                    ['х', 'h'],  ['ц', 'c'], ['ч', 'ch'],['ш', 'sh'], ['щ', 'shch'],
                    ['ъ', ''],  ['ы', 'y'], ['ь', ''],  ['э', 'e'], ['ю', 'yu'], ['я', 'ya'],

                    ['А', 'A'], ['Б', 'B'],  ['В', 'V'], ['Г', 'G'],
                    ['Д', 'D'], ['Е', 'E'], ['Ё', 'YO'],  ['Ж', 'ZH'], ['З', 'Z'],
                    ['И', 'I'], ['Й', 'Y'],  ['К', 'K'], ['Л', 'L'],
                    ['М', 'M'], ['Н', 'N'], ['О', 'O'],  ['П', 'P'],  ['Р', 'R'],
                    ['С', 'S'], ['Т', 'T'],  ['У', 'U'], ['Ф', 'F'],
                    ['Х', 'H'], ['Ц', 'C'], ['Ч', 'CH'], ['Ш', 'SH'], ['Щ', 'SHCH'],
                    ['Ъ', ''],  ['Ы', 'Y'],
                    ['Ь', ''],
                    ['Э', 'E'],
                    ['Ю', 'YU'],
                    ['Я', 'YA'],

                    ['a', 'a'], ['b', 'b'], ['c', 'c'], ['d', 'd'], ['e', 'e'],
                    ['f', 'f'], ['g', 'g'], ['h', 'h'], ['i', 'i'], ['j', 'j'],
                    ['k', 'k'], ['l', 'l'], ['m', 'm'], ['n', 'n'], ['o', 'o'],
                    ['p', 'p'], ['q', 'q'], ['r', 'r'], ['s', 's'], ['t', 't'],
                    ['u', 'u'], ['v', 'v'], ['w', 'w'], ['x', 'x'], ['y', 'y'],
                    ['z', 'z'],

                    ['A', 'A'], ['B', 'B'], ['C', 'C'], ['D', 'D'],['E', 'E'],
                    ['F', 'F'],['G', 'G'],['H', 'H'],['I', 'I'],['J', 'J'],['K', 'K'],
                    ['L', 'L'], ['M', 'M'], ['N', 'N'], ['O', 'O'],['P', 'P'],
                    ['Q', 'Q'],['R', 'R'],['S', 'S'],['T', 'T'],['U', 'U'],['V', 'V'],
                    ['W', 'W'], ['X', 'X'], ['Y', 'Y'], ['Z', 'Z'],

                    [' ', '-'],['0', '0'],['1', '1'],['2', '2'],['3', '3'],
                    ['4', '4'],['5', '5'],['6', '6'],['7', '7'],['8', '8'],['9', '9'],
                    ['-', '-'],['.', '.'],[',', ',']

            );

            var newStr = new String();

            for (var i = 0; i < str.length; i++) {

                ch = str.charAt(i);
                var newCh = '';

                for (var j = 0; j < cyr2latChars.length; j++) {
                    if (ch == cyr2latChars[j][0]) {
                        newCh = cyr2latChars[j][1];

                    }
                }
                // Если найдено совпадение, то добавляется соответствие, если нет - пустая строка
                newStr += newCh;

            }
            // Удаляем повторяющие знаки - Именно на них заменяются пробелы.
            // Так же удаляем символы перевода строки, но это наверное уже лишнее
            return newStr.replace(/[-]{2,}/gim, '-').replace(/\n/gim, '').replace(/(-|_)$/,'');
        }

        function titleConv2Lat() {
            var pligin_ex_links_url = document.getElementsByName('pligin_ex_links_url')[0];

            if (pligin_ex_links_url.value=='' && location.search.search('new') == '-1') {
                var header = document.getElementsByName('header')[0].value.toLowerCase().split('(')[0];
                //console.log(header)
                var l = header.length;

                if (l>25) {
                    header = header.split('.')[0];
                }

                l = header.length;

                if (l>25) {
                    header = header.substring(0,25);
                }
                pligin_ex_links_url.value = '/' + cyr2lat(header);
                //console.log(cyr2lat(header));
            }
        }
	function titleConv2LatNew(base){
		if(typeof(base) == 'undefined'){base = '/';}
		var pligin_ex_links_url = document.getElementsByName('pligin_ex_links_url')[0];
		if(pligin_ex_links_url.value == '' && location.search.search('new') == '-1'){
			var header = document.getElementsByName('header')[0].value.toLowerCase().split('(')[0];
			var l = header.length;
			if(l>25){header = header.split('.')[0];	}
			l = header.length;
			if(l>25){header = header.substring(0,25);}
			pligin_ex_links_url.value = base + cyr2lat(header);
			
		}
	}
