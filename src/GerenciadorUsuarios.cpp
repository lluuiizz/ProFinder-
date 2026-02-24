#include "../include/database/UserRepository.h"
#include "../include/GerenciadorUsuarios.h"
#include "../include/Cliente.h"
#include "../include/Fornecedor.h"


GerenciadorUsuarios::GerenciadorUsuarios(QObject *parent) : QObject(parent), m_usuarioLogado(nullptr) {
}

GerenciadorUsuarios::~GerenciadorUsuarios() {
}


QVariantMap GerenciadorUsuarios::cadastrarCliente(const QString& nome, const QString& email, const QString& cpf, const QString& dataNascimento, const QString& fotoPerfil) {
    QVariantMap _return_map;
    if (nome == "") {
        _return_map["status"] = false;
        _return_map["message"] = "Erro: Preencha o campo Nome!";

        return _return_map;
    }

    if (!email.contains('@')) {
        _return_map["status"] = false;
        _return_map["message"] = "Erro: Preencha com um Email Válido!";

        return _return_map;
    }

    if (cpf == "") {
        _return_map["status"] = false;
        _return_map["message"] = "Erro: Preencha com um CPF válido!";

        return _return_map;
    }

    if (dataNascimento == "") {
        _return_map["status"] = false;
        _return_map["message"] = "Erro: Preencha o Campo Data de Nascimento";

        return _return_map;
    }

    if (fotoPerfil == "") {
        _return_map["status"] = false;
        _return_map["message"] = "Insira uma foto de perfil";
    }


    Cliente _user(nome, email, cpf, dataNascimento, fotoPerfil);
    qsizetype _id;
    if ((_id = UserRepository::insertClient(_user)) == -1) {
        _return_map["status"] = false;
        _return_map["message"] = "Erro: Cliente não foi cadastrado no Banco de Dados";

        return _return_map;
    };

    if (m_usuarioLogado) delete m_usuarioLogado;
    m_usuarioLogado = new Cliente(_user);
    m_usuarioLogado->setId(_id);

    _return_map["status"] = true;
    _return_map["message"] = "Cliente Cadastrado com sucesso!";

    return _return_map;
}

QString GerenciadorUsuarios::cadastrarFornecedor(const QString& nome, const QString& email, const QString& cpf, const QString& dataNascimento, const QString& fotoPerfil, const QString& certificado, const QStringList& fotosServico, const QString& descricao, QVariantMap servicos) {
    // TODO: Implement the cadastrarFornecedor() Method
    if (nome == "") return "Erro: Preencha o campo Nome!";


    if (!email.contains("@")) return "Erro: Insira um Email Válido!";

    if (cpf == "") return "Erro: Preencha o campo CPF!";

    if (dataNascimento == "") return "Erro: Preencha o campo Data de Nascimento!";

    if (fotoPerfil == "") return "Erro: Selecione uma foto de perfil!";

    if (certificado == "") return "Erro: Insira um certificado de Antecedentes Criminais!";

    if (fotosServico.isEmpty() ) return "Erro: Você precisa adicionar pelo menos uma foto do seu serviço!";

    if(servicos.isEmpty()) return "Erro: Você precisa adicionar pelo menos um serviço!";

    Fornecedor _user(nome, email, cpf, dataNascimento, fotoPerfil, certificado, fotosServico, descricao, servicos);
    qsizetype _id;
    if ((_id = UserRepository::insertSupplier(_user)) == -1) {
        return "Erro: Fornecedor não foi cadastrado no Banco de Dados!";
    };

    if(m_usuarioLogado) delete m_usuarioLogado;

    m_usuarioLogado = new Fornecedor(_user);
    m_usuarioLogado->setId(_id);
    return "Fornecedor Cadastrado com sucesso!";
}

QVariantMap GerenciadorUsuarios::fazerLogin(const QString& email, const QString& cpf) {
    QVariantMap _login_info;
    if (!email.contains('@')) {
        _login_info["Success"] = 0;
        _login_info["Message"] = "Erro: Preencha com um Email válido!";
        _login_info["Type"] = "Null";

        return _login_info;
    }
    if (cpf.isEmpty()) {
        _login_info["Success"] = 0;
        _login_info["Message"] = "Erro: Preencha com um CPF válido!";
        _login_info["Type"] = "Null";
        return _login_info;

    }

    m_usuarioLogado =  UserRepository::loginUser(email, cpf);

    if (m_usuarioLogado == nullptr) {
        _login_info["Success"] = 0;
        _login_info["Message"] = "Erro: Usuário não foi encontrado!";
        _login_info["Type"] = "Null";
        return _login_info;
    }

    _login_info["Success"] = 1;
    _login_info["Message"] = "User connected to system!";
    _login_info["Type"] = m_usuarioLogado->getTipo();
    emit dadosAlterados();
    emit clienteAdicionado();
    return _login_info;
}

//QVariantMap GerenciadorUsuarios::obterDetalhesFornecedor(int index) {
    // TODO

//}


QVariantMap GerenciadorUsuarios::getUsuarioLogado() {
    QVariantMap res; res["logado"] = (m_usuarioLogado != nullptr);
    if (m_usuarioLogado) { res["nome"] = m_usuarioLogado->getNome(); res["tipo"] = m_usuarioLogado->getTipo(); }
    return res;
}

//void GerenciadorUsuarios::fazerLogout() { m_usuarioLogado = nullptr; }
/*
int GerenciadorUsuarios::getIndiceFornecedor(const QString& nome) {
    // TODO
    return 0;
}*/

/*
QStringList GerenciadorUsuarios::buscarFornecedores(const QString& termo) {
    QStringList nomes;
    for(Usuario* u : m_usuarios) if(u->getTipo() == "Fornecedor" && u->getNome().contains(termo, Qt::CaseInsensitive)) nomes << u->getNome();
    return nomes;
}*/
