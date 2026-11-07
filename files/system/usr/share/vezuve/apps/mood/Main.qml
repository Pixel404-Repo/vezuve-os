// Vezuve Mood - interface (Qt Quick). Signe Pixel 404.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Dialogs

ApplicationWindow {
    id: win
    width: 1340; height: 860
    minimumWidth: 1100; minimumHeight: 760
    visible: true
    title: "Vezuve Mood"
    color: "#140d22"

    // Mood affiche (selection) et Mood actif
    property string sel: backend.current
    property var m: moodById(sel)
    property color l1: m.l1
    property color l2: m.l2
    property int page: 0
    readonly property color txt: "#ffffff"
    readonly property color mut: Qt.rgba(1, 1, 1, 0.62)
    readonly property color glass: Qt.rgba(1, 1, 1, 0.07)
    Behavior on l1 { ColorAnimation { duration: 350 } }
    Behavior on l2 { ColorAnimation { duration: 350 } }

    function moodById(id) {
        for (var i = 0; i < backend.moods.length; i++) if (backend.moods[i].id === id) return backend.moods[i]
        return backend.moods[0]
    }
    function icon(n) { return iconDir + n + ".svg" }

    // ---------- fond : fond d'ecran du Mood, floute ----------
    Image {
        id: bgImg
        anchors.fill: parent
        source: backend.wallUrl(win.sel)
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
    }
    MultiEffect {
        anchors.fill: parent
        source: bgImg
        blurEnabled: true; blur: 1.0; blurMax: 64
        brightness: -0.18
        saturation: 0.15
    }
    Rectangle { anchors.fill: parent; gradient: Gradient {
        GradientStop { position: 0; color: Qt.rgba(0.08, 0.05, 0.14, 0.55) }
        GradientStop { position: 1; color: Qt.rgba(0.05, 0.03, 0.10, 0.75) } } }

    // ---------- composants ----------
    component Glass: Rectangle { radius: 22; color: win.glass }
    component Ico: Image { property string name; source: name !== "" ? win.icon(name) : ""; sourceSize.width: width * 2; sourceSize.height: height * 2; width: 22; height: 22; smooth: true }
    component IcoTile: Rectangle {
        property string name; property int size: 46
        width: size; height: size; radius: size * 0.3
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: win.l1 } GradientStop { position: 1; color: win.l2 } }
        Ico { name: parent.name; anchors.centerIn: parent; width: parent.size * 0.52; height: width }
    }
    component Label2: Text { color: win.txt; font.pixelSize: 15; font.weight: Font.DemiBold; wrapMode: Text.WordWrap }
    component Small: Text { color: win.mut; font.pixelSize: 13; font.weight: Font.Medium; wrapMode: Text.WordWrap }
    component GradButton: Rectangle {
        id: gb
        property string text; property string iconName: ""; property bool filled: true
        signal clicked()
        height: 44; width: row.implicitWidth + 36; radius: 14
        color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.16 : 0.10)
        Rectangle { anchors.fill: parent; radius: parent.radius; visible: gb.filled; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: win.l1 } GradientStop { position: 1; color: win.l2 } } }
        opacity: ma.pressed ? 0.8 : 1
        Row { id: row; anchors.centerIn: parent; spacing: 8
            Ico { visible: gb.iconName !== ""; name: gb.iconName; width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter }
            Text { text: gb.text; color: "white"; font.pixelSize: 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter } }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: gb.clicked() }
    }
    component Toggle: Rectangle {
        id: tg
        property bool on: false
        signal toggled(bool v)
        width: 54; height: 30; radius: 15
        color: Qt.rgba(1, 1, 1, 0.18)
        Rectangle { anchors.fill: parent; radius: parent.radius; visible: tg.on; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: win.l1 } GradientStop { position: 1; color: win.l2 } } }
        Rectangle { width: 24; height: 24; radius: 12; color: "white"; y: 3; x: tg.on ? tg.width - 27 : 3
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tg.toggled(!tg.on) }
    }
    component VSlider: RowLayout {
        id: vs
        property string label; property int value: 50
        signal moved(int v)
        spacing: 16
        Small { text: vs.label; Layout.preferredWidth: 130 }
        Slider {
            id: sl; Layout.fillWidth: true; from: 0; to: 100; value: vs.value; stepSize: 1
            onMoved: vs.moved(Math.round(value))
            background: Rectangle { x: sl.leftPadding; y: sl.topPadding + sl.availableHeight / 2 - 3
                width: sl.availableWidth; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.16)
                Rectangle { width: sl.visualPosition * parent.width; height: 6; radius: 3
                    gradient: Gradient { orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: win.l1 } GradientStop { position: 1; color: win.l2 } } } }
            handle: Rectangle { x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - 22); y: sl.topPadding + sl.availableHeight / 2 - 11
                width: 22; height: 22; radius: 11; color: "white" }
        }
        Small { text: Math.round(sl.value) + " %"; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
    }
    component RoundImage: Item {
        id: ri
        property url source; property real radius: 14
        Image { id: rimg; anchors.fill: parent; source: ri.source; fillMode: Image.PreserveAspectCrop; visible: false; asynchronous: true; sourceSize.width: 640 }
        Rectangle { id: rmask; anchors.fill: parent; radius: ri.radius; visible: false; layer.enabled: true }
        MultiEffect { anchors.fill: parent; source: rimg; maskEnabled: true; maskSource: rmask }
    }
    component MoodCard: Glass {
        id: mc
        property var mood
        readonly property bool active: mood.id === backend.current
        readonly property bool selected: mood.id === win.sel
        height: 170
        border.width: selected ? 3 : 0; border.color: win.l1
        RoundImage { x: 12; y: 12; width: parent.width - 24; height: 104; source: backend.wallUrl(mc.mood.id) }
        Rectangle { visible: mc.active; x: 22; y: 22; width: act.implicitWidth + 16; height: 22; radius: 11; color: Qt.rgba(0.2, 0.8, 0.5, 0.35)
            Text { id: act; anchors.centerIn: parent; text: "Actif"; color: "#c8ffe4"; font.pixelSize: 12; font.weight: Font.Bold } }
        RowLayout { x: 14; width: parent.width - 28; y: 126; height: 32
            Label2 { text: mc.mood.name; Layout.fillWidth: true; font.pixelSize: 17 }
            Row { Rectangle { width: 22; height: 22; radius: 11; color: mc.mood.l1 }
                  Rectangle { width: 22; height: 22; radius: 11; color: mc.mood.l2; x: -7 } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.sel = mc.mood.id; onDoubleClicked: backend.apply(mc.mood.id) }
    }

    // ---------- cartes ----------
    component WallCard: Glass {
        implicitHeight: wc.implicitHeight + 40
        ColumnLayout { id: wc; anchors.fill: parent; anchors.margins: 20; spacing: 14
            RowLayout { Layout.fillWidth: true; Label2 { text: "Fond d'écran du Mood " + win.m.name; font.pixelSize: 18; Layout.fillWidth: true }
                Rectangle { radius: 12; color: Qt.rgba(1, 1, 1, 0.08); height: 34; width: segRow.implicitWidth + 8
                    Row { id: segRow; anchors.centerIn: parent; spacing: 4
                        Rectangle { height: 28; width: t1.implicitWidth + 24; radius: 10
                            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: win.l1 } GradientStop { position: 1; color: win.l2 } }
                            Text { id: t1; anchors.centerIn: parent; text: "Image fixe"; color: "white"; font.pixelSize: 13; font.weight: Font.Bold } }
                        Rectangle { height: 28; width: t2.implicitWidth + 24; radius: 10; color: "transparent"
                            Text { id: t2; anchors.centerIn: parent; text: "Animé · bientôt"; color: win.mut; font.pixelSize: 13; font.weight: Font.Bold } } } } }
            RowLayout { spacing: 16; Layout.fillWidth: true
                RoundImage { Layout.preferredWidth: 200; Layout.preferredHeight: 124; source: backend.wallUrl(win.sel); radius: 14 }
                ColumnLayout { Layout.fillWidth: true; Layout.preferredWidth: 1; spacing: 10
                    Small { text: "Choisis l'image de ton choix pour ce Mood. Les couleurs et la musique du Mood restent les mêmes."; Layout.fillWidth: true }
                    Flow { Layout.fillWidth: true; spacing: 10
                        GradButton { text: "Mes images"; iconName: "folder"; filled: false; onClicked: fileDlg.open() }
                        GradButton { text: "Image d'origine"; filled: false; onClicked: backend.resetWall(win.sel) } } } } }
    }
    component AmbCard: Glass {
        implicitHeight: ac.implicitHeight + 40
        ColumnLayout { id: ac; anchors.fill: parent; anchors.margins: 20; spacing: 14
            Label2 { text: "Ambiance musicale"; font.pixelSize: 18 }
            Rectangle { Layout.fillWidth: true; height: 70; radius: 16; color: Qt.rgba(1, 1, 1, 0.06)
                RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 12
                    IcoTile { name: "music"; size: 46 }
                    ColumnLayout { spacing: 2; Layout.fillWidth: true
                        Label2 { text: moodById(backend.current).track }
                        Small { text: backend.playing ? "En lecture · en boucle" : "À l'arrêt" } }
                    Rectangle { width: 44; height: 44; radius: 22; color: Qt.rgba(1, 1, 1, 0.12)
                        Ico { name: backend.playing ? "stop" : "play"; anchors.centerIn: parent; width: 20; height: 20 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: backend.toggleAmbiance() } } } }
            VSlider { Layout.fillWidth: true; label: "Volume"; value: backend.volume; onMoved: v => backend.setVolume(v) }
            RowLayout { Layout.fillWidth: true
                Label2 { text: "Lancer la musique au changement de Mood"; Layout.fillWidth: true }
                Toggle { on: backend.musicOnChange; onToggled: v => backend.setMusicOnChange(v) } } }
    }
    component RgbCard: Glass {
        implicitHeight: rc.implicitHeight + 40
        ColumnLayout { id: rc; anchors.fill: parent; anchors.margins: 20; spacing: 10
            RowLayout { Layout.fillWidth: true
                Label2 { text: "Éclairage RGB"; font.pixelSize: 18; Layout.fillWidth: true }
                Rectangle { radius: 11; height: 24; width: st.implicitWidth + 18; color: Qt.rgba(0.2, 0.8, 0.5, 0.25)
                    Text { id: st; anchors.centerIn: parent; text: backend.status; color: "#c8ffe4"; font.pixelSize: 12; font.weight: Font.Bold } }
                Rectangle { width: 34; height: 34; radius: 10; color: Qt.rgba(1, 1, 1, 0.1)
                    Ico { name: "refresh"; anchors.centerIn: parent; width: 16; height: 16 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: backend.refreshDevices() } } }
            RowLayout { Layout.fillWidth: true
                Small { text: "L'éclairage suit le Mood"; Layout.fillWidth: true; color: win.txt; font.pixelSize: 15 }
                Toggle { on: backend.rgbEnabled; onToggled: v => backend.setRgbEnabled(v) } }
            Repeater {
                model: backend.devices
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: 14
                    IcoTile { name: modelData.kind; size: 44 }
                    ColumnLayout { spacing: 0; Layout.fillWidth: true
                        Label2 { text: modelData.label; Layout.fillWidth: true; elide: Text.ElideRight; wrapMode: Text.NoWrap }
                        Small { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight; wrapMode: Text.NoWrap } }
                    Row { Rectangle { width: 20; height: 20; radius: 10; color: win.l1 } Rectangle { width: 20; height: 20; radius: 10; color: win.l2; x: -6 } }
                    Toggle { on: modelData.follow; onToggled: v => backend.setDeviceFollow(modelData.name, v) }
                }
            }
            Small { visible: backend.devices.length === 0; text: backend.rgbAvailable ? "Aucun appareil trouvé. Clique sur ↻ pour relancer la recherche." : "Installe OpenRGB pour piloter la RAM, la carte graphique et les ventilateurs."; Layout.fillWidth: true }
            VSlider { Layout.fillWidth: true; label: "Luminosité"; value: backend.brightness; onMoved: v => backend.setBrightness(v) }
            Small { text: "Effets Respiration, Vague et Suit la musique : bientôt."; Layout.fillWidth: true } }
    }

    FileDialog {
        id: fileDlg
        title: "Choisir une image pour le Mood"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.jxl)"]
        onAccepted: backend.setCustomWall(win.sel, selectedFile.toString())
    }

    // ---------- mise en page ----------
    RowLayout {
        anchors.fill: parent; anchors.margins: 22; spacing: 22

        // Barre laterale
        Glass {
            Layout.preferredWidth: 250; Layout.fillHeight: true
            ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 6
                RowLayout { spacing: 12; Layout.bottomMargin: 18; Layout.topMargin: 6
                    IcoTile { name: "palette"; size: 40 }
                    Text { text: "Vezuve Mood"; color: "white"; font.pixelSize: 20; font.weight: Font.ExtraBold } }
                Repeater {
                    model: [["palette", "Moods"], ["image", "Fonds d'écran"], ["sparkle", "Éclairage RGB"], ["music", "Ambiance"], ["clock", "Planning"]]
                    delegate: Rectangle {
                        required property var modelData; required property int index
                        Layout.fillWidth: true; height: 48; radius: 14
                        color: nma.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                        Rectangle { anchors.fill: parent; radius: parent.radius; visible: win.page === index; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: win.l1 } GradientStop { position: 1; color: win.l2 } } }
                        Row { anchors.verticalCenter: parent.verticalCenter; x: 16; spacing: 14
                            Ico { name: modelData[0]; width: 20; height: 20; opacity: win.page === index ? 1 : 0.7; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: modelData[1]; color: win.page === index ? "white" : win.mut; font.pixelSize: 15; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { id: nma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.page = index }
                    }
                }
                Item { Layout.fillHeight: true }
                Small { text: "Vezuve OS · signé Pixel 404"; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
            }
        }

        // Contenu
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 18
            RowLayout { Layout.fillWidth: true
                ColumnLayout { spacing: 2; Layout.fillWidth: true
                    Text { text: "Mood " + win.m.name; color: "white"; font.pixelSize: 34; font.weight: Font.ExtraBold }
                    Small { text: "Couleurs, fond d'écran, éclairage RGB et musique changent ensemble" } }
                GradButton { text: "Créer un Mood · bientôt"; iconName: "plus"; filled: false; opacity: 0.6 }
                GradButton { text: win.sel === backend.current ? "Réappliquer" : "Appliquer"; iconName: "check"; onClicked: backend.apply(win.sel) }
            }
            RowLayout { Layout.fillWidth: true; spacing: 16
                Repeater { model: backend.moods; delegate: MoodCard { required property var modelData; mood: modelData; Layout.fillWidth: true } } }

            StackLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                currentIndex: win.page
                // 0 : vue d'ensemble
                RowLayout { spacing: 16
                    ColumnLayout { Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignTop; spacing: 16
                        WallCard { Layout.fillWidth: true }
                        AmbCard { Layout.fillWidth: true } }
                    RgbCard { Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.alignment: Qt.AlignTop } }
                // 1 : fonds d'ecran
                ColumnLayout { WallCard { Layout.fillWidth: true } Item { Layout.fillHeight: true } }
                // 2 : RGB
                ColumnLayout { RgbCard { Layout.fillWidth: true } Item { Layout.fillHeight: true } }
                // 3 : ambiance
                ColumnLayout { AmbCard { Layout.fillWidth: true } Item { Layout.fillHeight: true } }
                // 4 : planning
                ColumnLayout { Glass { Layout.fillWidth: true; Layout.preferredHeight: 160
                        ColumnLayout { anchors.fill: parent; anchors.margins: 20; spacing: 8
                            Label2 { text: "Planning"; font.pixelSize: 18 }
                            Small { text: "Bientôt : change de Mood automatiquement selon l'heure (par exemple Lofi Rain le soir)."; Layout.fillWidth: true } } }
                    Item { Layout.fillHeight: true } }
            }
        }
    }
}
