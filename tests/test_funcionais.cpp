#include <QtTest/QtTest>
#include <QVariantMap>
#include <QVariantList>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include "../include/GerenciadorUsuarios.h"
#include "../include/database/DatabaseManager.h"

class TestesFuncionais : public QObject {
    Q_OBJECT

private slots:
    void initTestCase() {
        // Certifique-se de que a conexão já está configurada aqui ou no main/repositório
        // Se a sua classe UserRepository já conecta, talvez não precise fazer nada aqui.
    }

    void initDatabase() {
        if (!DatabaseManager::instance().connect()) {
            qDebug() << "Erro de conexão: Não foi Possível se conectar com o Banco de Dados de ProFinder!";
            return ;
        }
        qDebug() << "Conectado ao banco de dados com sucesso!" ;
    }
    void init() {
        // Limpa o banco de dados antes de CADA teste
        // O CASCADE apaga também os dados de tabelas filhas (fornecedor_servicos, fornecedor_fotos)
        QSqlQuery query;
        if (!query.exec("TRUNCATE TABLE usuarios RESTART IDENTITY CASCADE")) {
            qDebug() << "Aviso: Falha ao limpar o banco de dados para os testes:" << query.lastError().text();
        }
    }

    void testCadastroCliente() {
        GerenciadorUsuarios manager;
        QVariantMap result = manager.cadastrarCliente("João Silva", "cliente1@email.com", "000.000.000-00", "2000-01-01", "foto.png");
        QVERIFY(result["status"].toBool() == true);

        result = manager.cadastrarCliente("", "vazio@email.com", "111.111.111-11", "2000-01-01", "foto.png");
        QVERIFY(result["status"].toBool() == false);

        result = manager.cadastrarCliente("Nome", "", "222.222.222-22", "2000-01-01", "foto.png");
        QVERIFY(result["status"].toBool() == false);
    }

    void testCadastroFornecedorCompleto() {
        GerenciadorUsuarios manager;
        QVariantMap servicos;
        servicos["Encanador"] = 5;

        QStringList fotos;
        fotos << "foto1.jpg";

        QVariantMap result = manager.cadastrarFornecedor(
            "João Fornecedor", "fornecedor1@email.com", "123.456.789-00", "2000-10-15",
            "foto.png", "certificado.pdf", fotos, "Trabalho com qualidade", servicos
        );
        QVERIFY(result["status"].toBool() == true);
    }

    void testCadastroFornecedorValidacaoCamposObrigatorios() {
        GerenciadorUsuarios manager;
        QVariantMap servicos;
        servicos["Encanador"] = 5;
        QStringList fotos;
        fotos << "foto1.jpg";

        QVariantMap result = manager.cadastrarFornecedor("", "falha1@email.com", "123.456.789-00", "2000-10-15", "perfil.jpg", "certificado.pdf", fotos, "Trabalho", servicos);
        QVERIFY(result["status"].toBool() == false);
    }

    void testCadastroFornecedorValidacaoFotos() {
        GerenciadorUsuarios manager;
        QVariantMap servicos;
        servicos["Encanador"] = 5;

        QStringList fotosVazias;
        QVariantMap result = manager.cadastrarFornecedor("Nome", "falha_foto_vazia@test.com", "123.456.789-00", "2000-10-15", "perfil.jpg", "cert.pdf", fotosVazias, "Desc", servicos);
        QVERIFY(result["status"].toBool() == false);

        QStringList fotosMuitas;
        fotosMuitas << "foto1.jpg" << "foto2.jpg" << "foto3.jpg" << "foto4.jpg" << "foto5.jpg" << "foto6.jpg";
        result = manager.cadastrarFornecedor("Nome", "falha_foto_muitas@test.com", "111.222.333-44", "2000-01-01", "perfil.jpg", "cert.pdf", fotosMuitas, "Desc", servicos);
        QVERIFY(result["status"].toBool() == false); // Requer validação de máx 5 fotos no C++

        QStringList fotos5;
        fotos5 << "1.jpg" << "2.jpg" << "3.jpg" << "4.jpg" << "5.jpg";

        // CORRIGIDO AQUI: Retornei o valor para 14 caracteres em vez de usar o CNPJ de 18
        result = manager.cadastrarFornecedor("Nome", "sucesso_fotos@test.com", "999.888.777-66", "2000-01-01", "perfil.jpg", "certificado.pdf", fotos5, "Descricao do trabalho", servicos);
        QVERIFY(result["status"].toBool() == true);
    }

    void testCadastroFornecedorValidacaoServicos() {
        GerenciadorUsuarios manager;
        QStringList fotos;
        fotos << "foto1.jpg";

        QVariantMap servicosVazios;
        QVariantMap result = manager.cadastrarFornecedor("Nome", "falha_servico@test.com", "123.456.789-00", "2000-01-01", "perfil.jpg", "cert.pdf", fotos, "Desc", servicosVazios);
        QVERIFY(result["status"].toBool() == false);

        QVariantMap servicosMultiplos;
        servicosMultiplos["Encanador"] = 5;

        result = manager.cadastrarFornecedor("Nome", "sucesso_servicos@test.com", "222.333.444-55", "2000-01-01", "perfil.jpg", "cert.pdf", fotos, "Desc", servicosMultiplos);
        QVERIFY(result["status"].toBool() == true);
    }

    void testCadastroFornecedorDescricaoOpcional() {
        GerenciadorUsuarios manager;
        QVariantMap servicos;
        servicos["Encanador"] = 5;
        QStringList fotos;
        fotos << "foto1.jpg";

        QVariantMap result = manager.cadastrarFornecedor("Nome", "sucesso_desc_vazia@test.com", "123.456.789-00", "2000-01-01", "perfil.jpg", "cert.pdf", fotos, "", servicos);
        QVERIFY(result["status"].toBool() == true);

        result = manager.cadastrarFornecedor("Nome2", "sucesso_desc_cheia@test.com", "987.654.321-00", "1990-02-02", "perfil2.jpg", "cert2.pdf", fotos, "Trabalho bom", servicos);
        QVERIFY(result["status"].toBool() == true);
    }
};

QTEST_MAIN(TestesFuncionais)
#include "test_funcionais.moc"
