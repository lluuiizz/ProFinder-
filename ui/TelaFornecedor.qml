import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: fornecedorPage

    Component.onCompleted: {
        // Check if user is logged in, if not redirect to login
        let usuario = gerenciador.getUsuarioLogado()
        if (!usuario.logado || usuario.tipo !== "Fornecedor") {
            stackView.clear()
            stackView.push("TelaInicial.qml")
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Label {
                text: "Meus Clientes"
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            Button{
                text: "Abrir Chat"
                highlighted: true

                // CONFIGURAÇÃO DO BOTÃO PARA CHAMAR A TELA DE CHAT
                onClicked: {
                    stackView.push("TelaChat.qml", {

                    })
                }


            }


            Button {
                text: "Sair"
                onClicked: {
                    gerenciador.fazerLogout()
                    stackView.clear()
                    stackView.push("TelaInicial.qml")
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        Label {
            text: "Clientes em contato:"
            font.bold: true
            font.pixelSize: 16
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: clientesList
                model: ListModel {
                    id: clientesModel
                    ListElement { nome: "João Silva"; email: "joao@email.com"; telefone: "(11) 98765-4321" }
                    ListElement { nome: "Maria Santos"; email: "maria@email.com"; telefone: "(11) 98765-4322" }
                    ListElement { nome: "Pedro Oliveira"; email: "pedro@email.com"; telefone: "(11) 98765-4323" }
                    ListElement { nome: "Ana Costa"; email: "ana@email.com"; telefone: "(11) 98765-4324" }
                    ListElement { nome: "Carlos Ferreira"; email: "carlos@email.com"; telefone: "(11) 98765-4325" }
                }

                delegate: Rectangle {
                    width: clientesList.width
                    height: 80
                    color: "#f5f5f5"
                    border.color: "#ddd"
                    border.width: 1
                    radius: 5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        Text {
                            text: nome
                            font.bold: true
                            font.pixelSize: 14
                        }

                        Text {
                            text: email
                            font.pixelSize: 12
                            color: "#666"
                        }

                        Text {
                            text: telefone
                            font.pixelSize: 12
                            color: "#666"
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    text: "Nenhum cliente em contato no momento."
                    visible: clientesModel.count === 0
                    color: "gray"
                }
            }
        }
    }
}
