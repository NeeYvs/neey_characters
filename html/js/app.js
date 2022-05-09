let Characters = [];
let selected = 1;

(() => {
    Kashacter = {};
    Kashacter.plane = false
    Kashacter.Characters = {}
    Kashacter.ShowUI = function(data) {
        $('body').show()
        $('.container').show()
        if(data.limit < 2) {
            $("#char2").html('<span class="add-blocked">Odblokuj Slot</span>')
            $("#char3").html('<span class="add-blocked">Odblokuj Slot</span>')
        } else {
            $("#char2").html('<span onclick="SelectCharacter(2, false)" class="add material-icons">add</span>')
            $("#char3").html('<span onclick="SelectCharacter(3, false)" class="add material-icons">add</span>')   
        }
        if(data.characters !== null) {
            Characters = data.characters
            Kashacter.Characters = {}
            $.each(data.characters, function (index, char) {
                let charid = index + 1
                var sex = char.sex
                if (sex == 'm') {
                    sex = 'Mężczyzna'
                } else {
                    sex = 'Kobieta'
                }
                Kashacter.Characters[charid] = charid
                let photo = char.photo == null ? "camera.png" : `https://res.cloudinary.com/fivecity/image/upload/v1621437104/test/${char.photo}` 
                Kashacter.plane = data.plane
                    $("#char" + charid).html('<div class="main-info"> <img class="avatar" src="' + photo + '"> <div class="align-right"><p id="character-name" class="bold">' + char.firstname + ' '  + char.lastname + '</p></div> </div> <div class="main"> <div class="panel"> <div class="info"> <p class="bold">PŁEĆ</p> <p class="info-desc" id="character-sex">' + sex + '</p> </div> </div> <div class="panel"> <div class="info"> <p class="bold">DATA URODZENIA</p> <p class="info-desc" id="character-birth">'+ char.dateofbirth +'</p> </div> </div> <div class="panel"> <div class="info"> <p class="bold">WZROST</p> <p class="info-desc" id="character-citizenship">' + char.height + 'cm</p> </div> </div> <div class="panel"> <div class="info"> <p class="bold">PRACA</p> <p class="info-desc" id="character-job">' + char.job + '</p> </div> </div> <div class="panel-button"> <button ' + `${char.canPick ? 'onclick="SelectCharacter(' + charid + ', true)"' : ''} class="${char.canPick ? 'submit' : 'submit-blocked'}">${char.canPick ? 'WYBIERZ POSTAĆ' : 'ODBLOKUJ POSTAĆ'}</button> `+'</div> </div> </div>')
            });
        }
    };

    Kashacter.CloseUI = function() {
        $('body').hide()
        $('.container').hide()
    };
    window.onload = function(e) {
        window.addEventListener('message', function(event) {
            switch(event.data.action) {
                case 'openui':
                    Kashacter.ShowUI(event.data);
                break;
            }
        })
    }
})();

SelectCharacter = function(x, y) {
    $.post("https://neey_characters/CharacterChosen", JSON.stringify({
        charid: x,
        ischar: y,
        plane: Kashacter.plane
    }));
    Kashacter.CloseUI();
}

$('#right').click(function(){
    switch(selected){
        case 1:
            $('.characters').animate({left: '-350px'}, 500)
            selected = 2
            break
        case 2:
            $('.characters').animate({left: '-700px'}, 500)
            selected = 3
            break
        case 3:
            $('.characters').animate({left: '0px'}, 500)
            selected = 1
            break
    }
    $.post("https://neey_characters/SwitchCharacter", JSON.stringify({
        charid: Kashacter.Characters[selected]
    }));
})

$('#left').click(function(){
    switch(selected){
        case 1:
            $('.characters').animate({left: '-700px'}, 500)
            selected = 3
            break
        case 2:
            $('.characters').animate({left: '0px'}, 500)
            selected = 1
            break
        case 3:
            $('.characters').animate({left: '-350px'}, 500)
            selected = 2
            break
    }
    $.post("https://neey_characters/SwitchCharacter", JSON.stringify({
        charid: Kashacter.Characters[selected]
    }));
})