#!/usr/bin/env python3
"""
Validação de integridade da base (roda no CI antes de aceitar um PR).
Falha RUIDOSAMENTE se os totais não baterem — princípio: automação que falha em silêncio é o pior modo de falha.
Uso: python schema/validate.py
"""
import csv, sys
from collections import defaultdict

ESPERADO_VALOR = 12226772422      # soma de r3.valor (R$, arredondado)
ESPERADO_QTD   = 59045            # soma de r3.qtd
POR_ANO = {2022:(2073786721,9876),2023:(2265597383,11062),2024:(2925597595,14349),
           2025:(3311392900,15629),2026:(1650397822,8129)}

def ler(path, delim=','):
    with open(path, newline='') as f:
        r = csv.reader(f, delimiter=delim); next(r)
        return [row for row in r if row and any(c.strip() for c in row)]

erros = []

# r3 — totais e reconciliação
r3 = ler('data/r3_matriz_cruzada.csv')
val=defaultdict(float); qtd=defaultdict(int); g_val=0.0; g_qtd=0
r3_por_incuf=defaultdict(float)
for a in r3:
    ano=int(a[0]); v=float(a[3]); q=int(a[4])
    val[ano]+=v; qtd[ano]+=q; g_val+=v; g_qtd+=q
    r3_por_incuf[(ano,a[1])]+=v
if round(g_val)!=ESPERADO_VALOR: erros.append(f"r3 soma valor {round(g_val)} != {ESPERADO_VALOR}")
if g_qtd!=ESPERADO_QTD:          erros.append(f"r3 soma qtd {g_qtd} != {ESPERADO_QTD}")
for ano,(ev,eq) in POR_ANO.items():
    if round(val[ano])!=ev: erros.append(f"r3 {ano} valor {round(val[ano])} != {ev}")
    if qtd[ano]!=eq:        erros.append(f"r3 {ano} qtd {qtd[ano]} != {eq}")

# r2 — reconciliação por UF x ano contra r3 (tolerância de centavos)
nome2uf={'Acre':'AC','Alagoas':'AL','Amapá':'AP','Amazonas':'AM','Bahia':'BA','Ceará':'CE','Distrito Federal':'DF','Espírito Santo':'ES','Goiás':'GO','Maranhão':'MA','Mato Grosso':'MT','Mato Grosso do Sul':'MS','Minas Gerais':'MG','Pará':'PA','Paraíba':'PB','Paraná':'PR','Pernambuco':'PE','Piauí':'PI','Rio de Janeiro':'RJ','Rio Grande do Norte':'RN','Rio Grande do Sul':'RS','Rondônia':'RO','Roraima':'RR','Santa Catarina':'SC','São Paulo':'SP','Sergipe':'SE','Tocantins':'TO'}
def braz(s): return float(s.replace('.','').replace(',','.')) if (',' in s) else float(s)
mism=0
for a in ler('data/r2_pj_regiao_uf.csv'):
    ano=int(a[0]); lab=a[1];
    if lab in nome2uf:
        v=braz(a[3]); d=abs(v - r3_por_incuf.get((ano,nome2uf[lab]),0))
        if d>0.5: mism+=1
if mism: erros.append(f"r2 vs r3: {mism} divergencias por UF/ano")

if erros:
    print("FALHA DE VALIDACAO:"); [print(" -",e) for e in erros]; sys.exit(1)
print("OK — base integra. r3: R$ %d / %d aportes. r2 reconcilia 100%% com r3." % (round(g_val), g_qtd))
