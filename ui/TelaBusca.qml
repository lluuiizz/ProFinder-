// ui/TelaBusca.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: buscaPage

    property int fornecedorSelecionadoIndex: -1

    function atualizarLista(termo = "") {
        let resultados = gerenciador.buscarFornecedoresComIndices(termo);
        listaModelo.clear();
        for (let i = 0; i < resultados.length; i++) {
            listaModelo.append({
                "detalhe": resultados[i].display,
                "index": resultados[i].index,
                "nome": resultados[i].nome
            });
        }
    }

    // --- NOVO: CONEXÃO REATIVA ---
    Connections {
        target: gerenciador
        // No Qt, sinais como 'dadosAlterados' tornam-se 'onDadosAlterados' no QML
        onFornecedorAdicionado: {
            console.log("Banco de dados atualizado! Atualizando lista...")
            atualizarLista(buscaInput.text);
        }
    }
    // -----------------------------

    Component.onCompleted: {
        // Show all suppliers as soon as the user logs in
        atualizarLista("");
        // Check if user is logged in, if not redirect to login
        let usuario = gerenciador.getUsuarioLogado();
        if (!usuario.logado || usuario.tipo !== "Cliente") {
            stackView.clear();
            stackView.push("TelaInicial.qml");
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Label {
                // Chama a nova função C++ sempre que a interface precisar atualizar
                text: fornecedorSelecionadoIndex >= 0 ? "Detalhes do Fornecedor" : "Buscar Fornecedores"
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            Label {
                text: "Total: " + gerenciador.quantidadeFornecedores
                font.bold: true
                color: "#666"
                visible: fornecedorSelecionadoIndex < 0
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
                visible: fornecedorSelecionadoIndex < 0
                onClicked: {
                    gerenciador.fazerLogout()
                    stackView.clear()
                    stackView.push("TelaInicial.qml")
                }
            }
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: fornecedorSelecionadoIndex >= 0 ? 1 : 0

        // Search/List View
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: buscaInput
                    Layout.fillWidth: true
                    placeholderText: "Digite o serviço ou nome"
                    onTextChanged: atualizarLista(text) // Opcional: Busca em tempo real ao digitar
                }
                Button {
                    text: "Buscar"
                    onClicked: atualizarLista(buscaInput.text)
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ListModel { id: listaModelo }
                delegate: ItemDelegate {
                    width: listView.width
                    height: 60
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        
                        Text {
                            text: detalhe.split(" - ")[0] // Name
                            font.bold: true
                            font.pixelSize: 14
                        }
                        
                        Text {
                            text: detalhe.split(" - ").slice(1).join(" - ") // Services, email, CPF/CNPJ
                            font.pixelSize: 12
                            color: "#666"
                            wrapMode: Text.Wrap
                        }
                    }
                    
                    onClicked: {
                        fornecedorSelecionadoIndex = model.index
                        if (fornecedorSelecionadoIndex >= 0) {
                            detalhesFornecedor = gerenciador.obterDetalhesFornecedor(fornecedorSelecionadoIndex)
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    text: "Nenhum fornecedor encontrado."
                    visible: listaModelo.count === 0
                    color: "gray"
                }
            }
        }

        // Details View
        ScrollView {
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: detalhesLayout.height + 40

            ColumnLayout {
                id: detalhesLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                spacing: 15

                // Profile Picture
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 150
                    height: 150
                    color: "#e0e0e0"
                    border.color: "#999"
                    border.width: 2
                    radius: 5
                    
                    Image {
                        id: fotoPerfilImage
                        anchors.fill: parent
                        anchors.margins: 5
                        fillMode: Image.PreserveAspectFit
                        source: detalhesFornecedor.fotoPerfil ? "file://" + detalhesFornecedor.fotoPerfil : ""
                        visible: detalhesFornecedor.fotoPerfil
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Sem foto"
                        visible: !detalhesFornecedor.fotoPerfil
                        color: "#999"
                    }
                }

                // Name
                Label {
                    text: "Nome: " + detalhesFornecedor.nome
                    font.bold: true
                    font.pixelSize: 18
                }

                // Email
                Label {
                    text: "E-mail: " + detalhesFornecedor.email
                    font.pixelSize: 14
                }

                // CPF/CNPJ
                Label {
                    text: "CPF/CNPJ: " + detalhesFornecedor.cpfCnpj
                    font.pixelSize: 14
                }

                // Services
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    Label {
                        text: "Serviços Oferecidos:"
                        font.bold: true
                        font.pixelSize: 14
                    }
                    
                    Repeater {
                        model: Object.keys(detalhesFornecedor.servicosComAnos || {})
                        delegate: Label {
                            text: modelData + " - " + detalhesFornecedor.servicosComAnos[modelData] + " anos de experiência"
                            font.pixelSize: 12
                            color: "#666"
                        }
                    }
                }

                // Work Description
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: detalhesFornecedor.descricaoTrabalho
                    
                    Label {
                        text: "Descrição do Trabalho:"
                        font.bold: true
                        font.pixelSize: 14
                    }
                    
                    Label {
                        text: detalhesFornecedor.descricaoTrabalho || ""
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }

                // Service Photos
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: detalhesFornecedor.fotosServico && detalhesFornecedor.fotosServico.length > 0
                    
                    Label {
                        text: "Fotos do Serviço:"
                        font.bold: true
                        font.pixelSize: 14
                    }
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        contentWidth: fotosRow.width
                        contentHeight: 200
                        
                        Row {
                            id: fotosRow
                            spacing: 10
                            
                            Repeater {
                                model: detalhesFornecedor.fotosServico || []
                                delegate: Rectangle {
                                    width: 180
                                    height: 180
                                    color: "#e0e0e0"
                                    border.color: "#999"
                                    border.width: 2
                                    radius: 5
                                    
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        fillMode: Image.PreserveAspectFit
                                        source: modelData ? "file://" + modelData : ""
                                    }
                                }
                            }
                        }
                    }
                }




                // Back Button
                Button {
                    Layout.fillWidth: true
                    text: "Voltar"
                    onClicked: {
                        fornecedorSelecionadoIndex = -1
                        detalhesFornecedor = {}
                    }
                }
            }
        }
    }

    // JavaScript property for supplier details
    property var detalhesFornecedor: ({})
}
