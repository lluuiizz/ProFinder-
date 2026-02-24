#include "../include/database/UserRepository.h"
#include "../include/database/DatabaseManager.h"
#include "Fornecedor.h"

#include <QSqlQuery>
#include <QSqlRecord>
#include <QJsonDocument>
#include <QJsonArray>
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

Usuario* UserRepository::loginUser(const QString &email, const QString &cpf) {

    QSqlQuery query(DatabaseManager::instance().database());
    if(!query.prepare("SELECT * FROM usuarios WHERE email = :_email AND cpf = :_cpf"))
        return nullptr;

    query.bindValue(":_email", email);
    query.bindValue(":_cpf", cpf);

    if (!query.exec()) {
        qDebug() << "Error at Searching User in the Database!" << query.lastError().text();
        return nullptr;
    } query.next();

    QString _nome = query.value("nome").toString();
    QString _email = query.value("email").toString();
    QString _cpf   = query.value("cpf").toString();
    QString _dataNasc = query.value("data_nascimento").toString();
    QString _fotoPerfil = query.value("foto_perfil").toString();
    QString _tipo_usuario = query.value("tipo_usuario").toString();
    qsizetype _id = query.value("id").toInt();


    if (_tipo_usuario == "CLIENTE")
        return new Cliente(_nome, _email, _cpf, _dataNasc, _fotoPerfil, _id);


    if (!query.prepare("SELECT * FROM fornecedores WHERE usuario_id = :_id")) {
        qDebug() << "Error while preparing Query to fornecedores: " << query.lastError().text();
        return nullptr;
    }   query.bindValue(":_id", _id);

    if (!query.exec()) {
        qDebug() << "Error while Executing Query to fornecedores: " << query.lastError().text();
        return nullptr;
    }

    if (!query.next()) return nullptr;
    QString certificado = query.value("certificado_antecedentes").toString();
    QString descricao   = query.value("descricao_trabalho").toString();

    if (!query.prepare(
            "SELECT * FROM fornecedor_servicos WHERE fornecedor_id = :_id")) {
        qDebug() << "Error while preparing Query to fornecedor_servicos: " << query.lastError().text();
        return nullptr;
    }   query.bindValue(":_id", _id);

    if (!query.exec()) {
        qDebug() << "Error while Executing Query to fornecedor_servicos" << query.lastError().text();
        return nullptr;
    }
    qDebug() << "Error at login User" << query.lastError().text();


    QVariantMap servicos_map;

    bool assert_success = false;
    while (query.next()) {
        assert_success = true;
        QString nome_servico = query.value("nome_servico").toString();
        int anos_experiencia = query.value("anos_experiencia").toInt();
        servicos_map.insert(nome_servico, anos_experiencia);
    }
    if (!assert_success) return nullptr; assert_success = false;

    if (!query.prepare(
            "SELECT * FROM fornecedor_fotos WHERE fornecedor_id = :_id")) {
        qDebug() << "Error while preparing Query to fornecedor_fotos: " << query.lastError().text();
        return nullptr;
    }   query.bindValue(":_id", _id);

    if (!query.exec()) {
        qDebug() << "Error while Executing Query to fornecedor_fotos" << query.lastError().text();
        return nullptr;
    }

    QStringList fotos_path_list;

    while (query.next()) {
        assert_success = true;
        QString path = query.value("foto").toString();
        fotos_path_list.push_back(path);
    }

    if (!assert_success) return nullptr;
    return new Fornecedor(_nome, _email, _cpf, _dataNasc, _fotoPerfil, certificado, fotos_path_list, descricao, servicos_map, _id);

}

QVariantList UserRepository::getSuppliersBySearchTerm(const QString& termo) {
    QVariantList listaFornecedores;
    QSqlQuery query;

    // A query agora possui o parâmetro :termo
    QString sql = R"(
        SELECT
            u.id, u.nome, u.email, u.cpf, u.data_nascimento, u.foto_perfil,
            f.cpf_cnpj, f.certificado_antecedentes, f.descricao_trabalho,
            (SELECT json_agg(ff.foto) FROM fornecedor_fotos ff WHERE ff.fornecedor_id = u.id) AS fotos_servico,
            (SELECT json_agg(json_build_object('nome_servico', fs.nome_servico, 'anos_experiencia', fs.anos_experiencia))
             FROM fornecedor_servicos fs WHERE fs.fornecedor_id = u.id) AS servicos
        FROM usuarios u
        JOIN fornecedores f ON u.id = f.usuario_id
        WHERE u.tipo_usuario = 'FORNECEDOR'
          AND (
              u.nome ILIKE :termo
              OR f.descricao_trabalho ILIKE :termo
              OR EXISTS (
                  SELECT 1 FROM fornecedor_servicos fs2
                  WHERE fs2.fornecedor_id = u.id AND fs2.nome_servico ILIKE :termo
              )
          );
    )";

    // Prepara a query
    if (!query.prepare(sql)) {
        qDebug() << "Erro ao preparar a busca de fornecedores:" << query.lastError().text();
        return listaFornecedores;
    }

    // Faz o bind do termo, adicionando os '%' para buscar em qualquer parte do texto
    QString termoBusca = "%" + termo + "%";
    query.bindValue(":termo", termoBusca);

    // Executa a query
    if (!query.exec()) {
        qDebug() << "Erro ao executar a busca de fornecedores:" << query.lastError().text();
        return listaFornecedores;
    }

    while (query.next()) {
        QVariantMap fornecedor;

        fornecedor["id"] = query.value("id").toInt();
        fornecedor["nome"] = query.value("nome").toString();
        fornecedor["email"] = query.value("email").toString();
        fornecedor["cpf"] = query.value("cpf").toString();
        fornecedor["data_nascimento"] = query.value("data_nascimento").toDate();
        fornecedor["foto_perfil"] = query.value("foto_perfil").toString();
        fornecedor["cpf_cnpj"] = query.value("cpf_cnpj").toString();
        fornecedor["certificado_antecedentes"] = query.value("certificado_antecedentes").toString();
        fornecedor["descricao_trabalho"] = query.value("descricao_trabalho").toString();

        QString fotosJson = query.value("fotos_servico").toString();
        if (!fotosJson.isEmpty()) {
            QJsonDocument doc = QJsonDocument::fromJson(fotosJson.toUtf8());
            fornecedor["fotos_servico"] = doc.array().toVariantList();
        } else {
            fornecedor["fotos_servico"] = QVariantList();
        }

        QString servicosJson = query.value("servicos").toString();
        if (!servicosJson.isEmpty()) {
            QJsonDocument doc = QJsonDocument::fromJson(servicosJson.toUtf8());
            fornecedor["servicos"] = doc.array().toVariantList();
        } else {
            fornecedor["servicos"] = QVariantList();
        }

        listaFornecedores.append(fornecedor);
    }

    return listaFornecedores;
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
