import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Page {
    id: chatPage

    // Propriedades para identificar com quem estamos falando
    property string nomeContato: "Nome do Profissional"
    property string status: "Online"

    header: ToolBar {
        background: Rectangle { color: "#075E54" } // Verde escuro WhatsApp
        RowLayout {
            anchors.fill: parent
            spacing: 10

            Button {
                text: "←"
                flat: true
                font.pixelSize: 20
                contentItem: Text { text: parent.text; color: "white"; font: parent.font }
                onClicked: stackView.pop()
            }

            Rectangle {
                width: 40; height: 40
                radius: 20
                color: "white"
                Image {
                    anchors.fill: parent
                    source: "file://./perfil_default.png" // Placeholder
                    fillMode: Image.PreserveAspectCrop
                }
            }

            ColumnLayout {
                spacing: 0
                Label {
                    text: chatPage.nomeContato
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                }
                Label {
                    text: chatPage.status
                    color: "#d1d1d1"
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true } // Espaçador

            Button {
                text: "📎"
                flat: true
                contentItem: Text { text: parent.text; color: "white"; font.pixelSize: 20 }
                onClicked: imageDialog.open()
            }
        }
    }

    // Fundo do Chat (Bege padrão)
    background: Rectangle {
        color: "#E5DDD5"
    }

    // Lista de Mensagens
    ListView {
        id: chatList
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8
        model: ListModel { id: chatModel }
        delegate: RowLayout {
            width: chatList.width
            layoutDirection: model.me ? Qt.RightToLeft : Qt.LeftToRight

            Rectangle {
                width: Math.min(msgText.implicitWidth + 20, chatList.width * 0.7)
                height: msgColumn.implicitHeight + 15
                radius: 8
                color: model.me ? "#DCF8C6" : "white" // Verde claro para mim, branco para o outro

                ColumnLayout {
                    id: msgColumn
                    anchors.fill: parent
                    anchors.margins: 8

                    // Se for imagem
                    Image {
                        visible: model.isImage
                        source: model.message
                        width: 200; height: 200
                        fillMode: Image.PreserveAspectFit
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Texto da mensagem
                    Text {
                        id: msgText
                        text: model.message
                        visible: !model.isImage
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "12:00"
                        font.pixelSize: 10
                        color: "gray"
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }

    // Barra de Digitação (Footer)
    footer: ToolBar {
        background: Rectangle { color: "#F0F0F0" }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 5

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 20
                color: "white"
                border.color: "#ddd"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 10

                    TextField {
                        id: messageInput
                        placeholderText: "Digite uma mensagem"
                        background: null
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "📷"
                        flat: true
                        onClicked: imageDialog.open()
                    }
                }
            }

            RoundButton {
                text: "➤"
                width: 45; height: 45
                palette.button: "#128C7E"
                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                onClicked: {
                    if (messageInput.text !== "") {
                        chatModel.append({"message": messageInput.text, "me": true, "isImage": false})
                        messageInput.text = ""
                        chatList.positionViewAtEnd()
                    }
                }
            }
        }
    }

    // Diálogo para anexar imagem
    FileDialog {
        id: imageDialog
        title: "Selecione uma imagem"
        onAccepted: {
            chatModel.append({"message": selectedFile.toString(), "me": true, "isImage": true})
            chatList.positionViewAtEnd()
        }
    }
}
