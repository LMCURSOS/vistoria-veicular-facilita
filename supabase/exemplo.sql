-- Facilita · Ficha de entrega de veículos
-- exemplo.sql · dados fictícios para o ambiente de TESTE (não rodar em produção)
-- Os mesmos do canvas: Toyota Etios RIO2A18 (placa fictícia) e condutores de exemplo.
-- As fotos apontam para caminhos de exemplo; troque pelas fotos reais pela tela de Frota.

insert into veiculos (modelo, placa, foto_traseira, foto_lateral_direita, foto_frente, foto_lateral_esquerda) values
  ('Toyota Etios', 'RIO2A18',
   'exemplo/etios/traseira.jpg', 'exemplo/etios/lateral_direita.jpg',
   'exemplo/etios/frente.jpg', 'exemplo/etios/lateral_esquerda.jpg')
on conflict (placa) do nothing;

insert into condutores (nome, cnh, validade_cnh, email, telefone) values
  ('Rafael Souza Lima',       '01234567890', '2031-03-15', 'rafael.lima@email.com',   '(21) 98765-4321'),
  ('Marcos Vinícius Pereira', '77788899900', '2032-06-05', 'marcos.pereira@email.com', '(21) 95432-1098'),
  ('Diego Araújo Pinto',      '55566677788', '2026-11-10', 'diego.pinto@email.com',    '(21) 91234-5678')   -- CNH vencida (D63)
on conflict (cnh) do nothing;
