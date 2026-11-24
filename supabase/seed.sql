-- Facilita · Ficha de entrega de veículos
-- seed.sql · dados fixos: os 28 pontos do mapa e os 16 componentes (19/11/2026)
-- Posições em % de cada vista, tiradas da moldura padrão (D66) usada no canvas.

insert into pontos_padrao (numero, vista, peca, x_pct, y_pct) values
  (1, 'traseira', 'Vidro traseiro', 8.82, 10.59),
  (2, 'traseira', 'Lanterna traseira esquerda', 5.69, 50.00),
  (3, 'traseira', 'Roda traseira esquerda', 10.39, 90.00),
  (4, 'traseira', 'Lanterna traseira direita', 93.14, 49.41),
  (5, 'traseira', 'Tampa traseira', 93.14, 89.41),
  (6, 'lateral_direita', 'Antena', 37.62, 4.84),
  (7, 'lateral_direita', 'Para-brisa', 88.65, 19.35),
  (8, 'lateral_direita', 'Lanterna traseira direita', 3.46, 37.10),
  (9, 'lateral_direita', 'Farol direito', 96.65, 55.38),
  (10, 'lateral_direita', 'Roda traseira direita', 7.35, 86.02),
  (11, 'lateral_direita', 'Porta traseira direita', 31.35, 95.16),
  (12, 'lateral_direita', 'Porta dianteira direita', 62.05, 94.62),
  (13, 'lateral_direita', 'Roda dianteira direita', 87.78, 87.63),
  (14, 'frente', 'Para-brisa', 11.72, 7.54),
  (15, 'frente', 'Farol direito', 6.25, 43.85),
  (16, 'frente', 'Roda dianteira direita', 12.11, 90.22),
  (17, 'frente', 'Capô', 93.75, 13.13),
  (18, 'frente', 'Retrovisor esquerdo', 93.75, 29.89),
  (19, 'frente', 'Farol esquerdo', 93.36, 49.44),
  (20, 'lateral_esquerda', 'Para-brisa', 5.91, 13.22),
  (21, 'lateral_esquerda', 'Teto', 40.11, 4.41),
  (22, 'lateral_esquerda', 'Farol esquerdo', 3.12, 52.34),
  (23, 'lateral_esquerda', 'Lanterna traseira esquerda', 96.88, 39.67),
  (24, 'lateral_esquerda', 'Roda dianteira esquerda', 6.99, 85.95),
  (25, 'lateral_esquerda', 'Porta dianteira esquerda', 32.15, 93.66),
  (26, 'lateral_esquerda', 'Porta traseira esquerda', 61.40, 93.66),
  (27, 'lateral_esquerda', 'Roda traseira esquerda', 88.49, 87.60),
  (28, 'frente', 'Retrovisor direito', 5.47, 25.42)
on conflict (numero) do update set vista = excluded.vista, peca = excluded.peca, x_pct = excluded.x_pct, y_pct = excluded.y_pct;

insert into componentes_padrao (id, nome, grupo, ordem) values
  (1, 'Antenas', 'externos', 1),
  (2, 'Bancos', 'internos', 1),
  (3, 'Calotas / Rodas', 'externos', 2),
  (4, 'Carpetes', 'internos', 2),
  (5, 'Espelhos', 'internos', 3),
  (6, 'Faróis', 'externos', 3),
  (7, 'Forrações', 'internos', 4),
  (8, 'Macaco', 'equipamentos', 1),
  (9, 'Estepe', 'equipamentos', 2),
  (10, 'Chave de roda', 'equipamentos', 3),
  (11, 'Triângulo', 'equipamentos', 4),
  (12, 'Rádio', 'internos', 5),
  (13, 'Extintor', 'internos', 6),
  (14, 'Chave de setas', 'internos', 7),
  (15, 'Pisca-alerta', 'internos', 8),
  (16, 'Cinto de segurança', 'internos', 9)
on conflict (id) do update set nome = excluded.nome, grupo = excluded.grupo, ordem = excluded.ordem;
