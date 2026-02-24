import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Page {
    id: cadastroPage

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Label {
                text: "Novo Usuário"
                font.pixelSize: 20
                Layout.fillWidth: true
            }

            Button {
                text: "Voltar"
                onClicked: {
                    stackView.pop()
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: formLayout.height + 40

        ColumnLayout {
            id: formLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 15

            ComboBox {
                id: tipoCombo
                Layout.fillWidth: true
                model: ["Cliente", "Fornecedor"]
            }

            TextField {
                id: nomeInput
                Layout.fillWidth: true
                placeholderText: "Nome completo (Required)"
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
                placeholderText: "CPF/CNPJ (Required)"
            }

            // Date of Birth
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                Label {
                    text: "Data de Nascimento (Required)"
                    font.bold: true
                }
                
                Button {
                    Layout.fillWidth: true
                    text: dataNascimentoInput ? "Data: " + dataNascimentoInput : "Selecionar Data de Nascimento"
                    onClicked: dataNascimentoDialog.open()
                }
            }

            // Profile Picture
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                Label {
                    text: "Foto de Perfil (Required)"
                    font.bold: true
                }
                
                Button {
                    Layout.fillWidth: true
                    text: fotoPerfilPath ? "Foto selecionada: " + fotoPerfilPath.split("/").pop() : "Selecionar Foto de Perfil"
                    onClicked: fotoPerfilDialog.open()
                }
            }

            // Supplier-specific fields
            ColumnLayout {
                id: fornecedorFields
                Layout.fillWidth: true
                visible: tipoCombo.currentText === "Fornecedor"
                spacing: 15

                // Service Photos
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    Label {
                        text: "Fotos do Serviço (Required: 1-5 fotos)"
                        font.bold: true
                    }
                    
                    Label {
                        text: "Fotos selecionadas: " + fotosServicoList.count + "/5"
                        color: fotosServicoList.count < 1 || fotosServicoList.count > 5 ? "red" : "green"
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: "Adicionar Foto"
                            enabled: fotosServicoList.count < 5
                            onClicked: fotosServicoDialog.open()
                        }
                        Button {
                            text: "Remover Última"
                            enabled: fotosServicoList.count > 0
                            onClicked: {
                                if (fotosServicoList.count > 0) {
                                    fotosServicoList.remove(fotosServicoList.count - 1)
                                }
                            }
                        }
                    }
                    
                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        orientation: ListView.Horizontal
                        model: fotosServicoList
                        delegate: Rectangle {
                            width: 50
                            height: 50
                            color: "#e0e0e0"
                            border.color: "#999"
                            Text {
                                anchors.centerIn: parent
                                text: path.split("/").pop().substring(0, 10) + "..."
                                font.pixelSize: 8
                            }
                        }
                    }
                }

                // Criminal Background Check Certificate
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    Label {
                        text: "Certificado de Antecedentes Criminais (Required)"
                        font.bold: true
                    }
                    
                    Button {
                        Layout.fillWidth: true
                        text: certificadoPath ? "Certificado selecionado: " + certificadoPath.split("/").pop() : "Selecionar Certificado"
                        onClicked: certificadoDialog.open()
                    }
                }

                // Work Description
                TextArea {
                    id: descricaoInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    placeholderText: "Descrição de como você trabalha (Optional)"
                    wrapMode: TextArea.Wrap
                }

                // Services Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Label {
                        text: "Serviços Oferecidos (Required: Selecione pelo menos 1)"
                        font.bold: true
                    }
                    
                    ComboBox {
                        id: servicoCombo
                        Layout.fillWidth: true
                        model: ["Encanador", "Eletricista", "Pintor", "Pedreiro", 
                                "Carpinteiro", "Jardineiro", "Limpeza", "Marceneiro",
                                "Soldador", "Técnico em Informática", "Designer", "Fotógrafo"]
                        onActivated: {
                            let servicoSelecionado = currentText
                            // Check if service is already selected
                            let found = false
                            for (let i = 0; i < servicosSelecionadosList.count; i++) {
                                if (servicosSelecionadosList.get(i).nome === servicoSelecionado) {
                                    // Service already selected, remove it
                                    servicosSelecionadosList.remove(i)
                                    found = true
                                    break
                                }
                            }
                            if (!found) {
                                // New service, open dialog for years
                                servicoSelecionadoTemporario = servicoSelecionado
                                anosInputDialog.open()
                            }
                            // Reset combo selection
                            currentIndex = -1
                        }
                    }
                    
                    // List of selected services
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: servicosSelecionadosList.count > 0
                        
                        Label {
                            text: "Serviços Selecionados:"
                            font.bold: true
                        }
                        
                        Repeater {
                            model: servicosSelecionadosList
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                
                                Label {
                                    text: nome + " - " + anos + " anos"
                                    Layout.fillWidth: true
                                }
                                
                                Button {
                                    text: "Remover"
                                    onClicked: {
                                        // Remove from list
                                        for (let i = 0; i < servicosSelecionadosList.count; i++) {
                                            if (servicosSelecionadosList.get(i).nome === nome) {
                                                servicosSelecionadosList.remove(i)
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Label {
                        text: servicosSelecionadosList.count === 0 ? "Nenhum serviço selecionado" : 
                              servicosSelecionadosList.count + " serviço(s) selecionado(s)"
                        color: servicosSelecionadosList.count === 0 ? "red" : "green"
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Cadastrar"
                onClicked: {

                    let returned_values = {};
                    if (tipoCombo.currentText === "Cliente") {
                        returned_values = gerenciador.cadastrarCliente(
                            nomeInput.text, 
                            emailInput.text,
                            cpfInput.text,
                            dataNascimentoInput,
                            fotoPerfilPath
                        );
                    } else {
                        // Convert services list to QVariantMap format
                        let servicosMap = {}
                        for (let i = 0; i < servicosSelecionadosList.count; i++) {
                            let item = servicosSelecionadosList.get(i)
                            servicosMap[item.nome] = item.anos
                        }
                        
                        // Convert photos list to QStringList
                        let fotosList = []
                        for (let i = 0; i < fotosServicoList.count; i++) {
                            fotosList.push(fotosServicoList.get(i).path)
                        }
                        
                        returned_values = gerenciador.cadastrarFornecedor(
                            nomeInput.text, 
                            emailInput.text,
                            cpfInput.text,
                            dataNascimentoInput,
                            fotoPerfilPath,
                            certificadoPath,
                            fotosList,
                            descricaoInput.text,
                            servicosMap
                        );
                    }

                    if (returned_values["status"] == false)
                        statusLabel.color = "red";
                    else
                        statusLabel.color = "green"
                    statusLabel.text = returned_values["message"];
                    // Clear all fields
                    nomeInput.text = ""
                    emailInput.text = ""
                    cpfInput.text = ""
                    dataNascimentoInput = ""
                    fotoPerfilPath = ""
                    certificadoPath = ""
                    fotosServicoList.clear()
                    descricaoInput.text = ""
                    servicosSelecionadosList.clear()



                    // Navigate to appropriate homepage after registration
                    Qt.callLater(function() {
                        let usuario = gerenciador.getUsuarioLogado()
                        if (usuario.logado) {
                            if (usuario.tipo === "CLIENTE") {
                                stackView.push("TelaBusca.qml")
                            } else if (usuario.tipo === "FORNECEDOR") {
                                stackView.push("TelaFornecedor.qml")
                            }
                        }
                    })
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

    // File dialogs
    FileDialog {
        id: fotoPerfilDialog
        title: "Selecionar Foto de Perfil"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Image files (*.png *.jpg *.jpeg)"]
        onAccepted: {
            fotoPerfilPath = selectedFile.toString().replace("file://", "")
        }
    }

    FileDialog {
        id: fotosServicoDialog
        title: "Selecionar Foto do Serviço"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Image files (*.png *.jpg *.jpeg)"]
        onAccepted: {
            if (fotosServicoList.count < 5) {
                fotosServicoList.append({"path": selectedFile.toString().replace("file://", "")})
            }
        }
    }

    FileDialog {
        id: certificadoDialog
        title: "Selecionar Certificado de Antecedentes"
        fileMode: FileDialog.OpenFile
        nameFilters: ["PDF files (*.pdf)", "Image files (*.png *.jpg *.jpeg)"]
        onAccepted: {
            certificadoPath = selectedFile.toString().replace("file://", "")
        }
    }

    // Date picker dialog
    Dialog {
        id: dataNascimentoDialog
        title: "Selecionar Data de Nascimento"
        anchors.centerIn: parent
        width: 300
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            
            Label {
                text: "Dia:"
            }
            SpinBox {
                id: diaSpinBox
                from: 1
                to: 31
                value: 1
            }
            
            Label {
                text: "Mês:"
            }
            SpinBox {
                id: mesSpinBox
                from: 1
                to: 12
                value: 1
            }
            
            Label {
                text: "Ano:"
            }
            SpinBox {
                id: anoSpinBox
                from: 1900
                to: new Date().getFullYear()
                value: 2000
            }
            
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Cancelar"
                    Layout.fillWidth: true
                    onClicked: dataNascimentoDialog.close()
                }
                Button {
                    text: "Confirmar"
                    Layout.fillWidth: true
                    onClicked: {
                        let mes = mesSpinBox.value < 10 ? "0" + mesSpinBox.value : mesSpinBox.value
                        let dia = diaSpinBox.value < 10 ? "0" + diaSpinBox.value : diaSpinBox.value
                        dataNascimentoInput = anoSpinBox.value + "-" + mes + "-" + dia
                        dataNascimentoDialog.close()
                    }
                }
            }
        }
    }

    // Dialog for years input
    Dialog {
        id: anosInputDialog
        title: "Anos de Experiência"
        anchors.centerIn: parent
        width: 300
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            
            Label {
                text: "Quantos anos de experiência você tem com " + servicoSelecionadoTemporario + "?"
            }
            
            SpinBox {
                id: anosSpinBox
                from: 0
                to: 50
                value: 0
            }
            
            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Cancelar"
                    Layout.fillWidth: true
                    onClicked: anosInputDialog.close()
                }
                Button {
                    text: "Confirmar"
                    Layout.fillWidth: true
                    onClicked: {
                        servicosSelecionadosList.append({
                            "nome": servicoSelecionadoTemporario,
                            "anos": anosSpinBox.value
                        })
                        anosSpinBox.value = 0
                        anosInputDialog.close()
                    }
                }
            }
        }
    }

    // JavaScript properties
    property string fotoPerfilPath: ""
    property string certificadoPath: ""
    property string servicoSelecionadoTemporario: ""
    property string dataNascimentoInput: ""
    
    ListModel {
        id: fotosServicoList
    }
    
    ListModel {
        id: servicosSelecionadosList
    }
}
