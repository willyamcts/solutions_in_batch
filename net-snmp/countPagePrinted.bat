@echo off

REM 
REM Data: 12/11/2019 (atualizado 04/12/19)
REM
REM Autor: Willyam Castro
REM
REM Obtém contagem de páginas impressas e modelo do dispositivo, exportando para um TXT
REM 
REM Requer instalação de Net-SNMP - http://www.net-snmp.org/
REM Necessário alterar linha 40, "ip_impressoras.txt" pelo caminho completo do arquivo
REM
REM
REM Melhoria: Fazer tratamento de erro e eliminar a criação de arquivos para concatenar strings
REM             Não ocorre erro de dados inconsistentes pois os arquivos gerados são apagados a 
REM              cada loop.
REM
REM
REM Exemplo de conteúdo "necessário" para arquivo definido na linha 40:
REM 192.168.0.60 - Impressora_da_sala
REM 192.168.0.50 - Impressora_do_escritorio
REM
REM Exemplo do arquivo de saída:
REM 192.168.0.60   -   Impressora_da_sala   -   HP Officejet Pro X476dw MFP    -   221396 
REM 192.168.0.50   -   Impressora_do_escritorio   -   HP LaserJet P4014    -   194682 

REM arquivo atual= %%"<"%~f0%%
REM http://batchscript.blogspot.com/2012/12/aprenda-o-for-de-uma-vez-por-todas.html


set outputFile=controle_impressao.txt

call:setTimeFile

call:delFilesTmp

call:getFileAddress

echo ------------------------------------------------------ >> %outputFile%

echo.
echo.
echo    Saida disponivel em: [ %outputFile% ]
pause

notepad %outputFile%


goto:eof



REM ============= // ======== Functions ========= // ==================

REM Lê arquivo que contém HOSTNAME + IP da impressora/Nº ID
:getFileAddress

	for /f "Tokens=1,2 delims=-" %%a in (ip_impressoras.txt) do (
		echo %%b %TAB% %%a

		REM chama funcao "getDataSNMP" passando IP e setor/No. respectivamente
		call:getDataSNMP %%a %%b

	)
goto:eof



REM Obtém dados via SNMP
:getDataSNMP
REM	echo                       @param recebido getDataSNMP: %1 %2

	REM Modelo do equipamento
	snmpwalk -Cc -v 1 -c public %1 1.3.6.1.2.1.25.3.2.1.3.1 >> %tmp%\walk.tmp
	
	REM Qtd de páginas impressas
	snmpwalk -Cc -v 1 -c public %1 1.3.6.1.2.1.43.10.2.1.4 >> %tmp%\walk.tmp

	timeout /t 2 /nobreak > nul
	call:outputFile %1 %2

goto:eof




REM Cria arquivo de saída com dados úteis
:outputFile
REM	echo                       @param recebido outputFile: %1 %2
	@echo.

	REM Le arquivo que contem retorno completo das linhas do SNMP
	for /f "Tokens=3 delims=:" %%A in (%tmp%\walk.tmp) do (

		REM Verifica se é numero (info da qtd páginas)
		if %%A gtr 0 (

			REM Gera arquivo contendo qtd de páginas
			echo %%A > %tmp%\snmp_page.tmp

			REM Le arquivo que contem qtd páginas
			for /f %%B in (%tmp%\snmp_page.tmp) do (
				
				REM Le arquivo que contem modelo do dispositivo 
				for /f "Tokens=*" %%C in (%tmp%\snmp_device.tmp) do (
					echo %1   -   %2   -   %%C   -   %%B >> %outputFile%
				)

			)
			
		REM Se não é numero, é string = modelo do dispositivo
		REM		entra primeiro nessa condição e posteriormente no IF
		) ELSE (
			
			REM Gera arquivo contendo modelo do dispositivo
			echo %%A > %tmp%\snmp_device.tmp
			
		)

	)

	timeout /t 2 /nobreak > nul
	call:delFilesTmp
	
echo -----------------------

goto:eof



REM Adiciona hora e data a cada execução
:setTimeFile

	echo. >> %outputFile%
	echo      %time:~0,8% - %date% >> %outputFile%

goto:eof



REM Remove arquivos gerados em execuções anteriores interrompidas
:delFilesTmp

	del %tmp%\snmp_page.tmp %tmp%\snmp_device.tmp %tmp%\walk.tmp

goto:eof


REM // Fazer a leitura do arquivo criado em getDataSNMP e filtrar o conteúdo útil > Exportar para outro arquivo de forma organizada;
REM Usar o delimitador " : " 
