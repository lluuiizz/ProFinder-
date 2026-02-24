// include/GerenciadorUsuarios.h

#ifndef GERENCIADORUSUARIOS_H
#define GERENCIADORUSUARIOS_H

#include <QObject>
#include <QVector>
#include <QStringList>
#include <QVariantMap>
#include <QVariantList>
#include "Usuario.h"

class GerenciadorUsuarios : public QObject {
    Q_OBJECT
//    Q_PROPERTY(int quantidadeFornecedores READ getQuantidadeFornecedores NOTIFY fornecedorAdicionado);
private:
    Usuario* m_usuarioLogado; // Currently logged in user

public:
    explicit GerenciadorUsuarios(QObject *parent = nullptr);
    ~GerenciadorUsuarios();


    /**
     *@brief Loga um Usuário no Sistema a partir do Email e CPF
     *@return Retorna um Map com Atributos: Success 0=fail, 1=sucess; Message= Message Returned; Type = CLIENTE/FORNECEDOR
     *
     * */
    Q_INVOKABLE QVariantMap fazerLogin(const QString& email, const QString& cpf);

 //   Q_INVOKABLE QVariantMap obterDetalhesFornecedor(int index);

    Q_INVOKABLE QVariantMap getUsuarioLogado();
    Q_INVOKABLE QVariantList atualizarListaFornecedores(const QString& termo);

    Q_INVOKABLE void fazerLogout();

//    Q_INVOKABLE int getIndiceFornecedor(const QString& nome);

//    Q_INVOKABLE QStringList buscarFornecedores(const QString& termo);
    int getQuantidadeUsuarios() const;

//    int getQuantidadeFornecedores() const;

//    Q_INVOKABLE QVariantList buscarFornecedoresComIndices(const QString& termo);

    Q_INVOKABLE QVariantMap cadastrarCliente(const QString& nome, const QString& email,
                                      const QString& cpf, const QString& dataNascimento,
                                      const QString& fotoPerfil);

    Q_INVOKABLE QVariantMap cadastrarFornecedor(const QString& nome, const QString& email,
                                         const QString& cpf, const QString& dataNascimento,
                                         const QString& fotoPerfil,
                                         const QString& certificado, const QStringList& fotosServico,
                                         const QString& descricao, QVariantMap servicos);
signals:
    /**
     * @brief Sinal emitido sempre que o banco de dados JSON/Vetor é modificado.
     */
    void dadosAlterados();

    /**
     *@brief Sinal emitido sempre que o banco de dados tiver um novo Fornecedor Adicionado
     **/
     void fornecedorAdicionado();

    /**
     *@brief Sinal emitido sempre que o banco de dados tiver um novo Cliente Adicionado
     **/
     void clienteAdicionado();
};

#endif
