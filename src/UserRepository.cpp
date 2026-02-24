#include "../include/database/UserRepository.h"
#include "../include/database/DatabaseManager.h"

#include <QSqlQuery>
#include <QSqlRecord>
#include <QDebug>

bool prepareInsertIntoUsuarios(QSqlQuery &_query, const Usuario &_user); // USED FOR INSERT INTO USUARIOS TABLE
bool prepareInsertIntoFornecedores(QSqlQuery &_query, const Fornecedor &_supplier, qsizetype _id);
bool prepareInsertIntoFornecedoresServicos(QSqlQuery &_query, const Fornecedor &_supplier, qsizetype _id);
bool prepareInsertIntoFornecedoresFotos(QSqlQuery &_query, const Fornecedor &_supplier, qsizetype _id);

qsizetype UserRepository::insertClient(const Cliente &_client) {
    QSqlQuery query(DatabaseManager::instance().database());

    if (!prepareInsertIntoUsuarios(query, _client)) return -1;

    if (query.exec()) {
      if (query.next()) {
          qsizetype _id_returned = query.value("id").toInt();
          qDebug() << "Usuario inserido com ID " << _id_returned;
          return _id_returned;
      }
    } else {
        qDebug() << "Erro ao inserir: " << query.lastError().text();

    }

    return -1;
}

qsizetype UserRepository::insertSupplier(const Fornecedor &_supplier) {
    QSqlQuery query(DatabaseManager::instance().database());

    if(!prepareInsertIntoUsuarios(query, _supplier)) return -1;

    qsizetype _id_returned;
    if (query.exec() && query.next()) {
        _id_returned = query.value("id").toInt();
        qDebug() << "Usuario Inserido com id -- " << _id_returned;
    } else {
        qDebug() << "Error ocurred while executing Database Query -- Insert Into Usuarios: " << query.lastError().text();
        return -1;

    }
    if(!prepareInsertIntoFornecedores(query, _supplier, _id_returned)) return -1;
    if (!query.exec()) {
      qDebug() << "Error At Inserting Fornecedor at Table"
               << query.lastError().text();
      return -1;
    }

    if (!prepareInsertIntoFornecedoresServicos(query, _supplier,_id_returned)) return -1;

    if (!query.exec()) {
        qDebug() << "Error At Inserting into fornecedor_servicos Table: " << query.lastError().text();
        return -1;
    }

    if (!prepareInsertIntoFornecedoresFotos(query, _supplier , _id_returned)) return -1;

    if (!query.exec()) {
        qDebug() << "Error while inserting into fornecedor_fotos" << query.lastError().text();
        return -1;
    }


    return _id_returned;
}

Cliente* UserRepository::loginUser(const QString &email, const QString &cpf) {

    QSqlQuery query(DatabaseManager::instance().database());
    if(!query.prepare("SELECT * FROM usuarios WHERE email = :_email AND cpf = :_cpf"))
        return nullptr;

    query.bindValue(":_email", email);
    query.bindValue(":_cpf", cpf);

    if (!query.exec()) {
        qDebug() << "Error at Searching User in the Database!" << query.lastError().text();
        return nullptr;
    }

    if (query.next()) {
        QString _nome = query.value("nome").toString();
        QString _email = query.value("email").toString();
        QString _cpf   = query.value("cpf").toString();
        QString _dataNasc = query.value("data_nascimento").toString();
        QString _fotoPerfil = query.value("foto_perfil").toString();
        QString _tipo_usuario = query.value("tipo_usuario").toString();
        qsizetype _id = query.value("id").toInt();


        if (_tipo_usuario == "CLIENTE")
            return new Cliente(_nome, _email, _cpf, _dataNasc, _fotoPerfil, _id);
        else
            // TODO: get supplier fields;
            return nullptr;
    }

    qDebug() << "Error at login User" << query.lastError().text();

    return nullptr;

}

bool prepareInsertIntoUsuarios(QSqlQuery &_query, const Usuario &_user) {
    if (!_query.prepare("INSERT INTO usuarios (tipo_usuario, nome, email, cpf, "
                       "data_nascimento, foto_perfil) VALUES (:tipo_usuario, :nome, "
                       ":email, :cpf, :dataNascimento, :fotoPerfil) RETURNING id")) {

        qDebug() << "Error at preparing Database _Query!";
        return false;
    }

    _query.bindValue(":tipo_usuario", _user.getTipo());
    _query.bindValue(":nome", _user.getNome());
    _query.bindValue(":email", _user.getEmail());
    _query.bindValue(":cpf", _user.getCpf());
    _query.bindValue(":dataNascimento", _user.getDataNascimento());
    _query.bindValue(":fotoPerfil", _user.getFotoPerfil());

    return true;
}


bool prepareInsertIntoFornecedores(QSqlQuery &_query, const Fornecedor &_supplier, qsizetype _id) {
    if (!_query.prepare("INSERT INTO fornecedores (usuario_id, cpf_cnpj, "
                       "certificado_antecedentes, descricao_trabalho) VALUES "
                       "(:usuario_id, :cpf_cnpj, :certificado, :descricao)")) {
        qDebug() << "Error while preparing _query to insert Fornecedor into fornecedores Table: " << _query.lastError().text();
        return false;
    }

    _query.bindValue(":usuario_id", _id);
    _query.bindValue(":cpf_cnpj", _supplier.getCpf());
    _query.bindValue(":certificado", _supplier.getCertificadoAntecedentes());
    _query.bindValue(":descricao", _supplier.getDescricaoTrabalho());

    return true;

}

bool prepareInsertIntoFornecedoresServicos(QSqlQuery &_query,
                                           const Fornecedor &_supplier,
                                           qsizetype _id) {

    QString values = "VALUES ";

    QVariantMap& servicos_map = _supplier.getServicosComAnos();
    QVariantMap::iterator srv_iter = servicos_map.begin();

    while (srv_iter != servicos_map.end()) {
        QString nome_servico = srv_iter.key();
        int anos_servico = srv_iter.value().toInt();

        values += QString("(%1, '%2', %3)").arg(_id).arg(nome_servico).arg(anos_servico);

        ++srv_iter;

        if (srv_iter != servicos_map.end())
            values+= ", ";
    }

    QString _query_string = QString("INSERT INTO fornecedor_servicos(fornecedor_id, nome_servico, anos_experiencia) %1").arg(values);

    qDebug() << _query_string << "\n\n";
    if (!_query.prepare(_query_string)) {
        qDebug() << "Error at preparing query string to fornecedor_servicos: " << _query.lastError().text();
        return false;

    }

    return true;
}

bool prepareInsertIntoFornecedoresFotos(QSqlQuery &_query,
                                        const Fornecedor &_supplier,
                                        qsizetype _id) {

     QString values = "VALUES ";

    QStringList fotos_list = _supplier.getFotosServico();
    QStringList::iterator fotos_iter = fotos_list.begin();

    while (fotos_iter != fotos_list.end()) {
        QString foto_path = *fotos_iter;
        values += QString("(%1, '%2')").arg(_id).arg(foto_path);

        ++fotos_iter;

        if (fotos_iter != fotos_list.end())
            values+= ", ";
    }

    QString _query_string = QString("INSERT INTO fornecedor_fotos(fornecedor_id, foto) %1").arg(values);

    qDebug() << _query_string << "\n\n";
    if (!_query.prepare(_query_string)) {
        qDebug() << "Error at preparing query string to fornecedor_servicos: " << _query.lastError().text();
        return false;

    }

    return true;
}
