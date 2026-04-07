const express = require("express");
const cors = require("cors");
const axios = require("axios");
const mp = require("mercadopago");

const MercadoPagoConfig =
  mp.MercadoPagoConfig || mp.default?.MercadoPagoConfig;
const Preference =
  mp.Preference || mp.default?.Preference;

const app = express();

app.use(express.json());
app.use(cors());

const ACCESS_TOKEN = "APP_USR-8832122465095574-040519-2a16d42189ec950c1d4d33e1bd05f0ad-14588412";

const client = new MercadoPagoConfig({
  accessToken: ACCESS_TOKEN,
});

// banco fake temporário só pra teste
const pedidos = {};

app.get("/", (req, res) => {
  res.send("API Mercado Pago rodando");
});

app.post("/criar-preferencia", async (req, res) => {
  try {
    const { titulo, preco, anuncioId, enderecoId, userId } = req.body;

    const pedidoId = `PED-${Date.now()}`;
    const preference = new Preference(client);

    const response = await preference.create({
      body: {
        items: [
          {
            title: titulo || "Produto",
            quantity: 1,
            unit_price: Number(preco || 10),
            currency_id: "BRL",
          },
        ],
        external_reference: pedidoId,
        notification_url:
          "https://unwept-derick-breedable.ngrok-free.dev/webhook/mercadopago",
        back_urls: {
          success: "meuapp://success",
          failure: "meuapp://failure",
          pending: "meuapp://pending",
        },
        auto_return: "approved",
      },
    });

    pedidos[pedidoId] = {
      pedidoId,
      anuncioId,
      enderecoId,
      userId,
      titulo,
      preco,
      status: "aguardando_pagamento",
      preferenceId: response.id,
      criadoEm: new Date().toISOString(),
    };

    res.json({
      pedidoId,
      id: response.id,
      init_point: response.init_point,
      sandbox_init_point: response.sandbox_init_point,
    });
  } catch (error) {
    console.log("ERRO AO CRIAR PREFERENCIA:");
    console.log(error?.response?.data || error);

    res.status(500).json({
      erro: "Erro ao criar preferência",
      detalhe: error?.response?.data || error?.message || "Erro desconhecido",
    });
  }
});

app.post("/webhook/mercadopago", async (req, res) => {
  try {
    console.log("=== WEBHOOK RECEBIDO ===");
    console.log("body:", req.body);
    console.log("query:", req.query);

    const tipo = req.body?.type || req.query?.type || req.query?.topic;
    const paymentId =
      req.body?.data?.id || req.query?.["data.id"] || req.query?.id;

    if (tipo !== "payment" || !paymentId) {
      console.log("Evento ignorado");
      return res.sendStatus(200);
    }

    const pagamento = await axios.get(
      `https://api.mercadopago.com/v1/payments/${paymentId}`,
      {
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
        },
      }
    );

    const dados = pagamento.data;

    console.log("=== PAGAMENTO CONSULTADO ===");
    console.log({
      id: dados.id,
      status: dados.status,
      external_reference: dados.external_reference,
      status_detail: dados.status_detail,
    });

    const pedidoId = dados.external_reference;

    if (pedidoId && pedidos[pedidoId]) {
      pedidos[pedidoId].paymentId = dados.id;
      pedidos[pedidoId].statusMercadoPago = dados.status;
      pedidos[pedidoId].statusDetail = dados.status_detail;
      pedidos[pedidoId].atualizadoEm = new Date().toISOString();
    }

    if (dados.status === "approved") {
      console.log("PAGAMENTO APROVADO");

      if (pedidoId && pedidos[pedidoId]) {
        pedidos[pedidoId].status = "pago";
      }
    } else if (dados.status === "pending") {
      console.log("Pagamento pendente");

      if (pedidoId && pedidos[pedidoId]) {
        pedidos[pedidoId].status = "aguardando_pagamento";
      }
    } else {
      console.log("Pagamento com outro status:", dados.status);

      if (pedidoId && pedidos[pedidoId]) {
        pedidos[pedidoId].status = "nao_pago";
      }
    }

    return res.sendStatus(200);
  } catch (error) {
    console.log("ERRO NO WEBHOOK:");
    console.log(error?.response?.data || error?.message || error);
    return res.sendStatus(500);
  }
});

// rota para o Flutter consultar
app.get("/pedido/:pedidoId/status", (req, res) => {
  const { pedidoId } = req.params;

  const pedido = pedidos[pedidoId];

  if (!pedido) {
    return res.status(404).json({
      erro: "Pedido não encontrado",
    });
  }

  return res.json({
    pedidoId: pedido.pedidoId,
    status: pedido.status,
    statusMercadoPago: pedido.statusMercadoPago || null,
    statusDetail: pedido.statusDetail || null,
  });
});

app.get("/pedidos", (req, res) => {
  res.json(pedidos);
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Servidor rodando na porta 3000");
});