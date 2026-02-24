import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: loginPage

    header: ToolBar {
        Label {
            text: "Login"
            font.pixelSize: 20
            anchors.centerIn: parent
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 20

        Label {
            text: "Entre com suas credenciais"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: emailInput
            Layout.fillWidth: true
            placeholderText: "E-mail (Required)"
            inputMethodHints: Qt.ImhEmailCharactersOnly
        }

        TextField {
            id: cpfInput
            Layout.fillWidth: true
            placeholderText: "CPF (Required)"
        }

        Button {
            Layout.fillWidth: true
            text: "Entrar"
            onClicked: {
                let resultado = gerenciador.fazerLogin(emailInput.text, cpfInput.text)
                if (resultado.Success == 1) {
                    statusLabel.text = "Conseguimos encontrar o usuário!"
                    statusLabel.color = "green";

                    Qt.callLater(function() {
                        let _user_type = resultado.Type;
                        if (_user_type == "CLIENTE")
                            stackView.push("TelaBusca.qml")
                        else
                            stackView.push("TelaFornecedor.qml")
                    })
                }

            }
        }

        Button {
            Layout.fillWidth: true
            text: "Voltar"
            onClicked: {
                stackView.pop()
            }
        }

        Label {
            id: statusLabel
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: ""
        }
    }
}
