#ifndef USERREPOSITORY_H_
#define USERREPOSITORY_H_

#include "../Cliente.h"
#include "../Fornecedor.h"

class UserRepository {
    private:
    UserRepository();

    public:
    static qsizetype insertClient(const Cliente& _client);
    static qsizetype insertSupplier(const Fornecedor& _supplier);
    static Usuario* loginUser(const QString& email, const QString& cpf);

    static bool getUser(int id);
};

#endif // USERREPOSITORY_H_
