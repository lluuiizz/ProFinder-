// ui/TelaBusca.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: buscaPage

    property int fornecedorSelecionadoIndex: -1
    property var detalhesFornecedor: ({})

    // --- NOVO: Variável para guardar os dados originais do C++ ---
    property var fornecedoresRaw: []

    function atualizarLista(termo = "") {
        // Recebe o QVariantList do C++ (array de objetos/maps)
        fornecedoresRaw = gerenciador.atualizarListaFornecedores(termo);
        listaModelo.clear();

        for (let i = 0; i < fornecedoresRaw.length; i++) {
            let f = fornecedoresRaw[i];

            // Monta um subtítulo combinando os nomes dos serviços oferecidos
            let servicosStr = "";
            if (f.servicos && f.servicos.length > 0) {
                servicosStr = f.servicos.map(s => s.nome_servico).join(", ");
            } else {
                servicosStr = "Nenhum serviço específico";
            }

            listaModelo.append({
                "nomeExibicao": f.nome,
                "subtitulo": servicosStr + " | " + f.email
            });
        }
    }

    Connections {
        target: gerenciador
        onFornecedorAdicionado: {
            console.log("Banco de dados atualizado! Atualizando lista...")
            atualizarLista(buscaInput.text);
        }
    }

    Component.onCompleted: {
        atualizarLista("");
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
                text: fornecedorSelecionadoIndex >= 0 ? "Detalhes do Fornecedor" : "Buscar Fornecedores"
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            Label {
                text: "Total: " + fornecedoresRaw.length
                font.bold: true
                color: "#666"
                visible: fornecedorSelecionadoIndex < 0
            }

            Button {
                text: "Abrir Chat"
                highlighted: true
                onClicked: {
                    stackView.push("TelaChat.qml", {})
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

        // --- TELA 0: Search/List View ---
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: buscaInput
                    Layout.fillWidth: true
                    placeholderText: "Digite o serviço, nome ou descrição..."
                    onTextChanged: atualizarLista(text)
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
                            text: model.nomeExibicao
                            font.bold: true
                            font.pixelSize: 14
                        }

                        Text {
                            text: model.subtitulo
                            font.pixelSize: 12
                            color: "#666"
                            wrapMode: Text.Wrap
                        }
                    }

                    onClicked: {
                        fornecedorSelecionadoIndex = model.index;
                        // NOVO: Pega o objeto completo diretamente do array bruto, sem fazer nova consulta ao C++!
                        if (fornecedorSelecionadoIndex >= 0) {
                            detalhesFornecedor = fornecedoresRaw[fornecedorSelecionadoIndex];
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

        // --- TELA 1: Details View ---
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

                // Foto de Perfil
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
                        // Atualizado para a chave retornada pelo BD
                        source: detalhesFornecedor.foto_perfil ? "file://" + detalhesFornecedor.foto_perfil : ""
                        visible: !!detalhesFornecedor.foto_perfil
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Sem foto"
                        visible: !detalhesFornecedor.foto_perfil
                        color: "#999"
                    }
                }

                Label {
                    text: "Nome: " + (detalhesFornecedor.nome || "")
                    font.bold: true
                    font.pixelSize: 18
                }

                Label {
                    text: "E-mail: " + (detalhesFornecedor.email || "")
                    font.pixelSize: 14
                }

                Label {
                    // Atualizado para a chave retornada pelo BD
                    text: "CPF/CNPJ: " + (detalhesFornecedor.cpf_cnpj || "")
                    font.pixelSize: 14
                }

                // Serviços (Usando o array de objetos JSON retornado pelo Postgres)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: detalhesFornecedor.servicos && detalhesFornecedor.servicos.length > 0

                    Label {
                        text: "Serviços Oferecidos:"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Repeater {
                        model: detalhesFornecedor.servicos || []
                        delegate: Label {
                            // modelData agora é um objeto: {nome_servico: "X", anos_experiencia: Y}
                            text: modelData.nome_servico + " - " + modelData.anos_experiencia + " anos de experiência"
                            font.pixelSize: 12
                            color: "#666"
                        }
                    }
                }

                // Descrição do Trabalho
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: !!detalhesFornecedor.descricao_trabalho

                    Label {
                        text: "Descrição do Trabalho:"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Label {
                        text: detalhesFornecedor.descricao_trabalho || ""
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }

                // Fotos do Serviço
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: detalhesFornecedor.fotos_servico && detalhesFornecedor.fotos_servico.length > 0

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
                                model: detalhesFornecedor.fotos_servico || []
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
                                        // modelData aqui é diretamente a string do caminho da foto
                                        source: modelData ? "file://" + modelData : ""
                                    }
                                }
                            }
                        }
                    }
                }

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
}
