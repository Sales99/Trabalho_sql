-- =====================================================================
-- Sistema de Gestão Operacional Pizzaria
-- Abolição Esfiharia e Pizzaria Ltda - ME (CNPJ 25.094.370/0001-66)
-- Script DDL - MySQL 8.0.16+ (InnoDB, utf8mb4)
-- Alinhado ao DER v1.1 e à Especificação de Requisitos v1.4
-- Grupo 3 - Grupo da Discórdia - FSA / ADS - SQL
-- =====================================================================

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ---------------------------------------------------------------------
-- Schema mydb
-- ---------------------------------------------------------------------
DROP SCHEMA IF EXISTS `mydb`;
CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `mydb`;

-- ---------------------------------------------------------------------
-- Tabela usuario: operador do sistema com perfil de acesso (RF10)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`usuario`;
CREATE TABLE IF NOT EXISTS `mydb`.`usuario` (
  `id_usuario` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(100) NOT NULL,
  `login` VARCHAR(50) NOT NULL,
  `senha_hash` CHAR(60) NOT NULL COMMENT 'Hash bcrypt (custo >= 12)',
  `perfil` ENUM('ATENDENTE', 'GERENTE', 'ADMINISTRADOR') NOT NULL DEFAULT 'ATENDENTE',
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_usuario`),
  UNIQUE INDEX `uk_usuario_login` (`login` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela cliente: pessoa que realiza pedidos (RF01, PR03 - LGPD)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`cliente`;
CREATE TABLE IF NOT EXISTS `mydb`.`cliente` (
  `id_cliente` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(100) NOT NULL,
  `telefone` VARCHAR(20) NULL COMMENT 'Telefone principal; anulado somente na anonimização',
  `email` VARCHAR(150) NULL COMMENT 'Opcional',
  `cpf` VARCHAR(255) NULL COMMENT 'Cifrado com AES-256 na aplicação, opcional',
  `cpf_hash` CHAR(64) NULL COMMENT 'SHA-256 do CPF, garante CPF único',
  `data_cadastro` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  `anonimizado` BOOLEAN NOT NULL DEFAULT FALSE,
  `data_anonimizacao` DATETIME NULL,
  PRIMARY KEY (`id_cliente`),
  UNIQUE INDEX `uk_cliente_telefone` (`telefone` ASC) VISIBLE,
  UNIQUE INDEX `uk_cliente_cpf_hash` (`cpf_hash` ASC) VISIBLE,
  CONSTRAINT `ck_cliente_telefone` CHECK (`anonimizado` = 1 OR `telefone` IS NOT NULL))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela endereco: endereço de entrega do cliente (RF01)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`endereco`;
CREATE TABLE IF NOT EXISTS `mydb`.`endereco` (
  `id_endereco` INT NOT NULL AUTO_INCREMENT,
  `id_cliente` INT NOT NULL,
  `logradouro` VARCHAR(150) NOT NULL,
  `numero` VARCHAR(10) NOT NULL,
  `complemento` VARCHAR(60) NULL,
  `bairro` VARCHAR(80) NOT NULL,
  `cep` VARCHAR(9) NOT NULL,
  `cidade` VARCHAR(80) NOT NULL,
  `uf` CHAR(2) NOT NULL,
  `ponto_referencia` VARCHAR(150) NULL,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_endereco`),
  INDEX `fk_endereco_cliente_idx` (`id_cliente` ASC) VISIBLE,
  CONSTRAINT `fk_endereco_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `mydb`.`cliente` (`id_cliente`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela categoria: agrupamento do cardápio (RF03)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`categoria`;
CREATE TABLE IF NOT EXISTS `mydb`.`categoria` (
  `id_categoria` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(50) NOT NULL,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_categoria`),
  UNIQUE INDEX `uk_categoria_nome` (`nome` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela produto: item do cardápio, preparado ou de revenda (RF03)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`produto`;
CREATE TABLE IF NOT EXISTS `mydb`.`produto` (
  `id_produto` INT NOT NULL AUTO_INCREMENT,
  `id_categoria` INT NOT NULL,
  `nome` VARCHAR(100) NOT NULL,
  `descricao` TEXT NULL,
  `tipo` ENUM('PREPARADO', 'REVENDA') NOT NULL,
  `tamanho` VARCHAR(20) NULL,
  `preco_tabela` DECIMAL(10,2) NOT NULL,
  `saldo_estoque` DECIMAL(10,3) NULL COMMENT 'Somente revenda',
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_produto`),
  INDEX `fk_produto_categoria_idx` (`id_categoria` ASC) VISIBLE,
  CONSTRAINT `ck_produto_preco` CHECK (`preco_tabela` > 0),
  CONSTRAINT `ck_produto_saldo` CHECK (`saldo_estoque` >= 0),
  CONSTRAINT `fk_produto_categoria`
    FOREIGN KEY (`id_categoria`)
    REFERENCES `mydb`.`categoria` (`id_categoria`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela historico_preco: alterações do preço de tabela (RF03, RN03)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`historico_preco`;
CREATE TABLE IF NOT EXISTS `mydb`.`historico_preco` (
  `id_historico_preco` INT NOT NULL AUTO_INCREMENT,
  `id_produto` INT NOT NULL,
  `id_usuario` INT NOT NULL,
  `preco_anterior` DECIMAL(10,2) NOT NULL,
  `preco_novo` DECIMAL(10,2) NOT NULL,
  `data_alteracao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_historico_preco`),
  INDEX `fk_historico_preco_produto_idx` (`id_produto` ASC) VISIBLE,
  INDEX `fk_historico_preco_usuario_idx` (`id_usuario` ASC) VISIBLE,
  CONSTRAINT `ck_historico_preco_valores` CHECK (`preco_anterior` > 0 AND `preco_novo` > 0),
  CONSTRAINT `fk_historico_preco_produto`
    FOREIGN KEY (`id_produto`)
    REFERENCES `mydb`.`produto` (`id_produto`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_historico_preco_usuario`
    FOREIGN KEY (`id_usuario`)
    REFERENCES `mydb`.`usuario` (`id_usuario`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela motoboy: entregador da pizzaria (RF15)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`motoboy`;
CREATE TABLE IF NOT EXISTS `mydb`.`motoboy` (
  `id_motoboy` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(100) NOT NULL,
  `telefone` VARCHAR(20) NOT NULL,
  `placa_moto` VARCHAR(8) NULL,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_motoboy`),
  UNIQUE INDEX `uk_motoboy_telefone` (`telefone` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela caixa: abertura e fechamento do caixa diário (RF12, RN09, RN15)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`caixa`;
CREATE TABLE IF NOT EXISTS `mydb`.`caixa` (
  `id_caixa` INT NOT NULL AUTO_INCREMENT,
  `id_usuario` INT NOT NULL,
  `data_abertura` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `valor_inicial` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `data_fechamento` DATETIME NULL,
  `valor_contado` DECIMAL(10,2) NULL,
  `situacao` ENUM('ABERTO', 'FECHADO') NOT NULL DEFAULT 'ABERTO',
  `caixa_aberto` TINYINT GENERATED ALWAYS AS (IF(`situacao` = 'ABERTO', 1, NULL)) STORED COMMENT 'Coluna gerada: um caixa aberto por vez (RN09)',
  `observacao` TEXT NULL,
  PRIMARY KEY (`id_caixa`),
  UNIQUE INDEX `uk_caixa_aberto` (`caixa_aberto` ASC) VISIBLE,
  INDEX `fk_caixa_usuario_idx` (`id_usuario` ASC) VISIBLE,
  CONSTRAINT `ck_caixa_valores` CHECK (`valor_inicial` >= 0 AND `valor_contado` >= 0),
  CONSTRAINT `ck_caixa_datas` CHECK (`data_fechamento` >= `data_abertura`),
  CONSTRAINT `fk_caixa_usuario`
    FOREIGN KEY (`id_usuario`)
    REFERENCES `mydb`.`usuario` (`id_usuario`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela repasse_motoboy: acerto do motoboy no fim do turno (RF11, RN11)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`repasse_motoboy`;
CREATE TABLE IF NOT EXISTS `mydb`.`repasse_motoboy` (
  `id_repasse_motoboy` INT NOT NULL AUTO_INCREMENT,
  `id_motoboy` INT NOT NULL,
  `id_caixa` INT NOT NULL,
  `data_turno` DATE NOT NULL,
  `quantidade_entregas` INT NOT NULL DEFAULT 0 COMMENT 'Valor consolidado',
  `valor_total` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Valor consolidado',
  PRIMARY KEY (`id_repasse_motoboy`),
  UNIQUE INDEX `uk_repasse_motoboy_turno` (`id_motoboy` ASC, `data_turno` ASC) VISIBLE,
  INDEX `fk_repasse_motoboy_caixa_idx` (`id_caixa` ASC) VISIBLE,
  CONSTRAINT `ck_repasse_valores` CHECK (`quantidade_entregas` >= 0 AND `valor_total` >= 0),
  CONSTRAINT `fk_repasse_motoboy_motoboy`
    FOREIGN KEY (`id_motoboy`)
    REFERENCES `mydb`.`motoboy` (`id_motoboy`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_repasse_motoboy_caixa`
    FOREIGN KEY (`id_caixa`)
    REFERENCES `mydb`.`caixa` (`id_caixa`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela pedido: pedido do cliente, para entrega ou retirada (RF02, RF07)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`pedido`;
CREATE TABLE IF NOT EXISTS `mydb`.`pedido` (
  `id_pedido` INT NOT NULL AUTO_INCREMENT,
  `id_cliente` INT NOT NULL,
  `id_usuario` INT NOT NULL,
  `id_endereco` INT NULL COMMENT 'Opcional na retirada',
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tipo_pedido` ENUM('ENTREGA', 'RETIRADA') NOT NULL,
  `situacao` ENUM('ABERTO', 'EM_PREPARO', 'SAIU_PARA_ENTREGA', 'ENTREGUE', 'CANCELADO') NOT NULL DEFAULT 'ABERTO',
  `desconto` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `valor_total` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Total persistido e mantido por regra (RN05)',
  `data_cancelamento` DATETIME NULL,
  `motivo_cancelamento` TEXT NULL,
  PRIMARY KEY (`id_pedido`),
  INDEX `fk_pedido_cliente_idx` (`id_cliente` ASC) VISIBLE,
  INDEX `fk_pedido_usuario_idx` (`id_usuario` ASC) VISIBLE,
  INDEX `fk_pedido_endereco_idx` (`id_endereco` ASC) VISIBLE,
  INDEX `idx_pedido_data_hora` (`data_hora` ASC) VISIBLE,
  CONSTRAINT `ck_pedido_endereco` CHECK (`tipo_pedido` = 'RETIRADA' OR `id_endereco` IS NOT NULL),
  CONSTRAINT `ck_pedido_valores` CHECK (`desconto` >= 0 AND `valor_total` >= 0),
  CONSTRAINT `fk_pedido_cliente`
    FOREIGN KEY (`id_cliente`)
    REFERENCES `mydb`.`cliente` (`id_cliente`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_pedido_usuario`
    FOREIGN KEY (`id_usuario`)
    REFERENCES `mydb`.`usuario` (`id_usuario`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_pedido_endereco`
    FOREIGN KEY (`id_endereco`)
    REFERENCES `mydb`.`endereco` (`id_endereco`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela item_pedido: produtos de cada pedido (RF02, RN03)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`item_pedido`;
CREATE TABLE IF NOT EXISTS `mydb`.`item_pedido` (
  `id_item_pedido` INT NOT NULL AUTO_INCREMENT,
  `id_pedido` INT NOT NULL,
  `id_produto` INT NOT NULL,
  `quantidade` DECIMAL(10,3) NOT NULL,
  `preco_unitario_venda` DECIMAL(10,2) NOT NULL COMMENT 'Preço congelado na venda (RN03)',
  `observacao` TEXT NULL,
  PRIMARY KEY (`id_item_pedido`),
  INDEX `fk_item_pedido_pedido_idx` (`id_pedido` ASC) VISIBLE,
  INDEX `fk_item_pedido_produto_idx` (`id_produto` ASC) VISIBLE,
  CONSTRAINT `ck_item_pedido_quantidade` CHECK (`quantidade` > 0),
  CONSTRAINT `ck_item_pedido_preco` CHECK (`preco_unitario_venda` >= 0),
  CONSTRAINT `fk_item_pedido_pedido`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `mydb`.`pedido` (`id_pedido`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_item_pedido_produto`
    FOREIGN KEY (`id_produto`)
    REFERENCES `mydb`.`produto` (`id_produto`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela item_sabor: sabores da pizza meio a meio (RN07, RN23)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`item_sabor`;
CREATE TABLE IF NOT EXISTS `mydb`.`item_sabor` (
  `id_item_sabor` INT NOT NULL AUTO_INCREMENT,
  `id_item_pedido` INT NOT NULL,
  `id_produto` INT NOT NULL,
  PRIMARY KEY (`id_item_sabor`),
  UNIQUE INDEX `uk_item_sabor` (`id_item_pedido` ASC, `id_produto` ASC) VISIBLE,
  INDEX `fk_item_sabor_produto_idx` (`id_produto` ASC) VISIBLE,
  CONSTRAINT `fk_item_sabor_item_pedido`
    FOREIGN KEY (`id_item_pedido`)
    REFERENCES `mydb`.`item_pedido` (`id_item_pedido`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_item_sabor_produto`
    FOREIGN KEY (`id_produto`)
    REFERENCES `mydb`.`produto` (`id_produto`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela historico_situacao_pedido: mudanças de situação (RF07, RN10)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`historico_situacao_pedido`;
CREATE TABLE IF NOT EXISTS `mydb`.`historico_situacao_pedido` (
  `id_historico_situacao_pedido` INT NOT NULL AUTO_INCREMENT,
  `id_pedido` INT NOT NULL,
  `id_usuario` INT NOT NULL,
  `situacao_anterior` ENUM('ABERTO', 'EM_PREPARO', 'SAIU_PARA_ENTREGA', 'ENTREGUE', 'CANCELADO') NULL,
  `situacao_nova` ENUM('ABERTO', 'EM_PREPARO', 'SAIU_PARA_ENTREGA', 'ENTREGUE', 'CANCELADO') NOT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_historico_situacao_pedido`),
  INDEX `fk_historico_situacao_pedido_pedido_idx` (`id_pedido` ASC) VISIBLE,
  INDEX `fk_historico_situacao_pedido_usuario_idx` (`id_usuario` ASC) VISIBLE,
  CONSTRAINT `fk_historico_situacao_pedido_pedido`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `mydb`.`pedido` (`id_pedido`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_historico_situacao_pedido_usuario`
    FOREIGN KEY (`id_usuario`)
    REFERENCES `mydb`.`usuario` (`id_usuario`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela pagamento: pagamento recebido por pedido (RF13, RN08, RN17)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`pagamento`;
CREATE TABLE IF NOT EXISTS `mydb`.`pagamento` (
  `id_pagamento` INT NOT NULL AUTO_INCREMENT,
  `id_pedido` INT NOT NULL,
  `id_caixa` INT NOT NULL,
  `forma_pagamento` ENUM('DINHEIRO', 'DEBITO', 'CREDITO', 'VALE_REFEICAO', 'VALE_ALIMENTACAO', 'PIX') NOT NULL,
  `valor` DECIMAL(10,2) NOT NULL,
  `valor_recebido` DECIMAL(10,2) NULL COMMENT 'Somente dinheiro; troco = valor_recebido - valor',
  `bandeira_vale` VARCHAR(30) NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_pagamento`),
  INDEX `fk_pagamento_pedido_idx` (`id_pedido` ASC) VISIBLE,
  INDEX `fk_pagamento_caixa_idx` (`id_caixa` ASC) VISIBLE,
  CONSTRAINT `ck_pagamento_valor` CHECK (`valor` > 0),
  CONSTRAINT `ck_pagamento_troco` CHECK (`forma_pagamento` <> 'DINHEIRO' OR `valor_recebido` >= `valor`),
  CONSTRAINT `fk_pagamento_pedido`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `mydb`.`pedido` (`id_pedido`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_pagamento_caixa`
    FOREIGN KEY (`id_caixa`)
    REFERENCES `mydb`.`caixa` (`id_caixa`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela estorno: devolução de valor de pedido cancelado (RF08, PR02)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`estorno`;
CREATE TABLE IF NOT EXISTS `mydb`.`estorno` (
  `id_estorno` INT NOT NULL AUTO_INCREMENT,
  `id_pedido` INT NOT NULL,
  `id_caixa` INT NOT NULL,
  `id_usuario` INT NOT NULL COMMENT 'Usuário aprovador',
  `valor` DECIMAL(10,2) NOT NULL,
  `forma_estorno` VARCHAR(30) NOT NULL,
  `motivo` TEXT NOT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_estorno`),
  INDEX `fk_estorno_pedido_idx` (`id_pedido` ASC) VISIBLE,
  INDEX `fk_estorno_caixa_idx` (`id_caixa` ASC) VISIBLE,
  INDEX `fk_estorno_usuario_idx` (`id_usuario` ASC) VISIBLE,
  CONSTRAINT `ck_estorno_valor` CHECK (`valor` > 0),
  CONSTRAINT `fk_estorno_pedido`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `mydb`.`pedido` (`id_pedido`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_estorno_caixa`
    FOREIGN KEY (`id_caixa`)
    REFERENCES `mydb`.`caixa` (`id_caixa`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_estorno_usuario`
    FOREIGN KEY (`id_usuario`)
    REFERENCES `mydb`.`usuario` (`id_usuario`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela entrega: entrega de um pedido por um motoboy (RF11, RN16)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`entrega`;
CREATE TABLE IF NOT EXISTS `mydb`.`entrega` (
  `id_entrega` INT NOT NULL AUTO_INCREMENT,
  `id_pedido` INT NOT NULL,
  `id_motoboy` INT NOT NULL,
  `id_repasse_motoboy` INT NULL COMMENT 'Opcional até o acerto',
  `taxa_entrega` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `data_saida` DATETIME NULL,
  `data_entrega` DATETIME NULL,
  PRIMARY KEY (`id_entrega`),
  UNIQUE INDEX `uk_entrega_pedido` (`id_pedido` ASC) VISIBLE,
  INDEX `fk_entrega_motoboy_idx` (`id_motoboy` ASC) VISIBLE,
  INDEX `fk_entrega_repasse_motoboy_idx` (`id_repasse_motoboy` ASC) VISIBLE,
  CONSTRAINT `ck_entrega_taxa` CHECK (`taxa_entrega` >= 0),
  CONSTRAINT `ck_entrega_datas` CHECK (`data_entrega` >= `data_saida`),
  CONSTRAINT `fk_entrega_pedido`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `mydb`.`pedido` (`id_pedido`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_entrega_motoboy`
    FOREIGN KEY (`id_motoboy`)
    REFERENCES `mydb`.`motoboy` (`id_motoboy`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_entrega_repasse_motoboy`
    FOREIGN KEY (`id_repasse_motoboy`)
    REFERENCES `mydb`.`repasse_motoboy` (`id_repasse_motoboy`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela fornecedor: empresa que fornece ingredientes e insumos (RF05)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`fornecedor`;
CREATE TABLE IF NOT EXISTS `mydb`.`fornecedor` (
  `id_fornecedor` INT NOT NULL AUTO_INCREMENT,
  `razao_social` VARCHAR(150) NOT NULL,
  `nome_fantasia` VARCHAR(150) NULL,
  `cnpj` VARCHAR(18) NOT NULL,
  `telefone` VARCHAR(20) NULL,
  `email` VARCHAR(150) NULL,
  `nome_contato` VARCHAR(100) NULL,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_fornecedor`),
  UNIQUE INDEX `uk_fornecedor_cnpj` (`cnpj` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela ingrediente: ingrediente ou insumo da produção (RF14, RN24)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`ingrediente`;
CREATE TABLE IF NOT EXISTS `mydb`.`ingrediente` (
  `id_ingrediente` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(100) NOT NULL,
  `unidade_medida` VARCHAR(10) NOT NULL COMMENT 'kg, g, L, un, saco',
  `saldo_estoque` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `estoque_minimo` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `custo_unitario` DECIMAL(10,2) NULL,
  `ativo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_ingrediente`),
  UNIQUE INDEX `uk_ingrediente_nome` (`nome` ASC) VISIBLE,
  CONSTRAINT `ck_ingrediente_saldo` CHECK (`saldo_estoque` >= 0 AND `estoque_minimo` >= 0),
  CONSTRAINT `ck_ingrediente_custo` CHECK (`custo_unitario` >= 0))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela movimentacao_estoque: entradas, saídas e ajustes (RF06, PR04)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`movimentacao_estoque`;
CREATE TABLE IF NOT EXISTS `mydb`.`movimentacao_estoque` (
  `id_movimentacao_estoque` INT NOT NULL AUTO_INCREMENT,
  `id_ingrediente` INT NOT NULL,
  `id_fornecedor` INT NULL COMMENT 'Obrigatório somente na entrada',
  `id_usuario` INT NOT NULL,
  `tipo` ENUM('ENTRADA', 'SAIDA', 'AJUSTE') NOT NULL,
  `quantidade` DECIMAL(10,3) NOT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `numero_nota_fiscal` VARCHAR(50) NULL,
  `custo_unitario` DECIMAL(10,2) NULL,
  `lote` VARCHAR(30) NULL,
  `data_validade` DATE NULL,
  `motivo` TEXT NULL,
  PRIMARY KEY (`id_movimentacao_estoque`),
  INDEX `fk_movimentacao_estoque_ingrediente_idx` (`id_ingrediente` ASC) VISIBLE,
  INDEX `fk_movimentacao_estoque_fornecedor_idx` (`id_fornecedor` ASC) VISIBLE,
  INDEX `fk_movimentacao_estoque_usuario_idx` (`id_usuario` ASC) VISIBLE,
  CONSTRAINT `ck_movimentacao_quantidade` CHECK ((`tipo` IN ('ENTRADA', 'SAIDA') AND `quantidade` > 0) OR (`tipo` = 'AJUSTE' AND `quantidade` <> 0)),
  CONSTRAINT `ck_movimentacao_fornecedor` CHECK (`tipo` <> 'ENTRADA' OR `id_fornecedor` IS NOT NULL),
  CONSTRAINT `ck_movimentacao_validade` CHECK (`data_validade` >= CAST(`data_hora` AS DATE)),
  CONSTRAINT `ck_movimentacao_custo` CHECK (`custo_unitario` >= 0),
  CONSTRAINT `fk_movimentacao_estoque_ingrediente`
    FOREIGN KEY (`id_ingrediente`)
    REFERENCES `mydb`.`ingrediente` (`id_ingrediente`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_movimentacao_estoque_fornecedor`
    FOREIGN KEY (`id_fornecedor`)
    REFERENCES `mydb`.`fornecedor` (`id_fornecedor`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_movimentacao_estoque_usuario`
    FOREIGN KEY (`id_usuario`)
    REFERENCES `mydb`.`usuario` (`id_usuario`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------------------
-- Tabela log_auditoria: trilha de auditoria append-only (RNF01, RNF10)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `mydb`.`log_auditoria`;
CREATE TABLE IF NOT EXISTS `mydb`.`log_auditoria` (
  `id_log_auditoria` INT NOT NULL AUTO_INCREMENT,
  `id_usuario` INT NOT NULL,
  `tabela_afetada` VARCHAR(64) NOT NULL,
  `id_registro` INT NOT NULL COMMENT 'Chave do registro afetado',
  `operacao` VARCHAR(10) NOT NULL,
  `data_hora` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `valor_anterior` TEXT NULL,
  `valor_novo` TEXT NULL,
  PRIMARY KEY (`id_log_auditoria`),
  INDEX `fk_log_auditoria_usuario_idx` (`id_usuario` ASC) VISIBLE,
  CONSTRAINT `ck_log_auditoria_operacao` CHECK (`operacao` IN ('INSERT', 'UPDATE', 'DELETE')),
  CONSTRAINT `fk_log_auditoria_usuario`
    FOREIGN KEY (`id_usuario`)
    REFERENCES `mydb`.`usuario` (`id_usuario`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
