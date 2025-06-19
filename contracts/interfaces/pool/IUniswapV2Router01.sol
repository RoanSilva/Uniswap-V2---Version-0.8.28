// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IUniswapV2Router01
 * @author Uniswap V2 Router Interface
 * @notice Interface para o contrato Uniswap V2 Router (versão 01).
 * @dev Define a estrutura padrão para operações de liquidez, swaps e consultas de preços no Uniswap V2.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Organização modular com seções claras para consultas, liquidez e swaps.
 *      - Recomendações implícitas de segurança para implementações (ex.: validação de endereços, proteção contra reentrância, verificação de deadlines).
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
interface IUniswapV2Router01 {
    // ================================
    //        Funções de Consulta
    // ================================

    /**
     * @notice Retorna o endereço da fábrica de pares Uniswap V2.
     * @dev Usado para interagir com a fábrica que cria e gerencia pares de liquidez.
     * @return Endereço da fábrica.
     */
    //function factory() external pure returns (address);

    /**
     * @notice Retorna o endereço do token WETH usado pelo router.
     * @dev WETH é o token Wrapped ETH, usado em pares envolvendo ETH.
     * @return Endereço do contrato WETH.
     */
    //function WETH() external pure returns (address);

    // ================================
    //      Adição de Liquidez
    // ================================

    /**
     * @notice Adiciona liquidez a um par de tokens.
     * @dev Deve:
     *      - Verificar que `tokenA` e `tokenB` são endereços válidos e distintos.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountAMin` e `amountBMin` protejam contra slippage excessivo.
     *      - Verificar que `deadline` não está expirado (block.timestamp <= deadline).
     *      - Ordenar os tokens para manter a ordenação canônica (token0 < token1).
     * @param tokenA Endereço do primeiro token do par.
     * @param tokenB Endereço do segundo token do par.
     * @param amountADesired Quantidade desejada de tokenA a ser depositada.
     * @param amountBDesired Quantidade desejada de tokenB a ser depositada.
     * @param amountAMin Quantidade mínima de tokenA aceita (proteção contra slippage).
     * @param amountBMin Quantidade mínima de tokenB aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens de liquidez.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amountA Quantidade final de tokenA depositada.
     * @return amountB Quantidade final de tokenB depositada.
     * @return liquidity Quantidade de tokens de liquidez emitidos.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Adiciona liquidez a um par token/ETH.
     * @dev Deve:
     *      - Verificar que `token` é um endereço válido.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountTokenMin` e `amountETHMin` protejam contra slippage.
     *      - Verificar que `deadline` não está expirado.
     *      - Processar o valor de ETH enviado com `msg.value`.
     * @param token Endereço do token do par.
     * @param amountTokenDesired Quantidade desejada do token a ser depositada.
     * @param amountTokenMin Quantidade mínima do token aceita (proteção contra slippage).
     * @param amountETHMin Quantidade mínima de ETH aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens de liquidez.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amountToken Quantidade final de token depositada.
     * @return amountETH Quantidade final de ETH depositada.
     * @return liquidity Quantidade de tokens de liquidez emitidos.
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    // ================================
    //      Remoção de Liquidez
    // ================================

    /**
     * @notice Remove liquidez de um par de tokens.
     * @dev Deve:
     *      - Verificar que `tokenA` e `tokenB` são endereços válidos e distintos.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountAMin` e `amountBMin` protejam contra slippage.
     *      - Verificar que `deadline` não está expirado.
     *      - Queimar os tokens de liquidez fornecidos.
     * @param tokenA Endereço do primeiro token do par.
     * @param tokenB Endereço do segundo token do par.
     * @param liquidity Quantidade de tokens de liquidez a serem removidos.
     * @param amountAMin Quantidade mínima de tokenA aceita (proteção contra slippage).
     * @param amountBMin Quantidade mínima de tokenB aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens retirados.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amountA Quantidade de tokenA recebida.
     * @return amountB Quantidade de tokenB recebida.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Remove liquidez de um par token/ETH.
     * @dev Deve:
     *      - Verificar que `token` é um endereço válido.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountTokenMin` e `amountETHMin` protejam contra slippage.
     *      - Verificar que `deadline` não está expirado.
     *      - Reembolsar ETH ao destinatário.
     * @param token Endereço do token do par.
     * @param liquidity Quantidade de tokens de liquidez a serem removidos.
     * @param amountTokenMin Quantidade mínima do token aceita (proteção contra slippage).
     * @param amountETHMin Quantidade mínima de ETH aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens e ETH retirados.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amountToken Quantidade de token recebida.
     * @return amountETH Quantidade de ETH recebida.
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Remove liquidez de um par de tokens usando permissão via assinatura (EIP-2612).
     * @dev Deve:
     *      - Validar a assinatura (v, r, s) e o `deadline`.
     *      - Verificar que `tokenA`, `tokenB`, e `to` não são endereços zero.
     *      - Garantir que `amountAMin` e `amountBMin` protejam contra slippage.
     *      - Usar `approveMax` para definir a aprovação máxima, se necessário.
     * @param tokenA Endereço do primeiro token do par.
     * @param tokenB Endereço do segundo token do par.
     * @param liquidity Quantidade de tokens de liquidez a serem removidos.
     * @param amountAMin Quantidade mínima de tokenA aceita (proteção contra slippage).
     * @param amountBMin Quantidade mínima de tokenB aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens retirados.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @param approveMax Se verdadeiro, aprova o máximo possível de tokens.
     * @param v Componente da assinatura ECDSA.
     * @param r Componente da assinatura ECDSA.
     * @param s Componente da assinatura ECDSA.
     * @return amountA Quantidade de tokenA recebida.
     * @return amountB Quantidade de tokenB recebida.
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Remove liquidez de um par token/ETH usando permissão via assinatura (EIP-2612).
     * @dev Deve:
     *      - Validar a assinatura (v, r, s) e o `deadline`.
     *      - Verificar que `token` e `to` não são endereços zero.
     *      - Garantir que `amountTokenMin` e `amountETHMin` protejam contra slippage.
     *      - Usar `approveMax` para definir a aprovação máxima, se necessário.
     * @param token Endereço do token do par.
     * @param liquidity Quantidade de tokens de liquidez a serem removidos.
     * @param amountTokenMin Quantidade mínima do token aceita (proteção contra slippage).
     * @param amountETHMin Quantidade mínima de ETH aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens e ETH retirados.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @param approveMax Se verdadeiro, aprova o máximo possível de tokens.
     * @param v Componente da assinatura ECDSA.
     * @param r Componente da assinatura ECDSA.
     * @param s Componente da assinatura ECDSA.
     * @return amountToken Quantidade de token recebida.
     * @return amountETH Quantidade de ETH recebida.
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    // ================================
    //        Funções de Swap
    // ================================

    /**
     * @notice Troca uma quantidade exata de tokens por outros tokens através de um ou mais pares.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e pelo menos um par.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountOutMin` protege contra slippage.
     *      - Verificar que `deadline` não está expirado.
     * @param amountIn Quantidade exata de tokens de entrada.
     * @param amountOutMin Quantidade mínima de tokens de saída aceita.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Troca tokens para obter uma quantidade exata de tokens de saída.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e pelo menos um par.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountInMax` limita a entrada de tokens.
     *      - Verificar que `deadline` não está expirado.
     * @param amountOut Quantidade exata de tokens de saída desejada.
     * @param amountInMax Quantidade máxima de tokens de entrada permitida.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Troca uma quantidade exata de ETH por tokens através de um ou mais pares.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e começa com WETH.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountOutMin` protege contra slippage.
     *      - Verificar que `deadline` não está expirado.
     *      - Processar o valor de ETH enviado com `msg.value`.
     * @param amountOutMin Quantidade mínima de tokens de saída aceita.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    /**
     * @notice Troca tokens por uma quantidade exata de ETH através de um ou mais pares.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e termina com WETH.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountInMax` limita a entrada de tokens.
     *      - Verificar que `deadline` não está expirado.
     * @param amountOut Quantidade exata de ETH desejada.
     * @param amountInMax Quantidade máxima de tokens de entrada permitida.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá o ETH.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Troca uma quantidade exata de tokens por ETH através de um ou mais pares.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e termina com WETH.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountOutMin` protege contra slippage.
     *      - Verificar que `deadline` não está expirado.
     * @param amountIn Quantidade exata de tokens de entrada.
     * @param amountOutMin Quantidade mínima de ETH aceita.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá o ETH.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Troca ETH por uma quantidade exata de tokens através de um ou mais pares.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e começa com WETH.
     *      - Validar que `to` não é o endereço zero.
     *      - Verificar que `deadline` não está expirado.
     *      - Processar o valor de ETH enviado com `msg.value`.
     * @param amountOut Quantidade exata de tokens de saída desejada.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    // ================================
    //     Funções de Consulta de Preço
    // ================================

    /**
     * @notice Calcula a quantidade de tokenB equivalente a uma quantidade de tokenA, com base nas reservas.
     * @dev Usado para estimar proporções de liquidez sem taxas.
     *      Fórmula: amountB = (amountA * reserveB) / reserveA.
     * @param amountA Quantidade de tokenA.
     * @param reserveA Reserva de tokenA no par.
     * @param reserveB Reserva de tokenB no par.
     * @return amountB Quantidade equivalente de tokenB.
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    /**
     * @notice Calcula a quantidade de saída para uma quantidade de entrada, considerando as reservas e taxas.
     * @dev Usado para estimar o resultado de um swap, incluindo taxas do Uniswap (0,3%).
     *      Fórmula: amountOut = (amountIn * reserveOut * 997) / (reserveIn * 1000 + amountIn * 997).
     * @param amountIn Quantidade de tokens de entrada.
     * @param reserveIn Reserva de tokens de entrada no par.
     * @param reserveOut Reserva de tokens de saída no par.
     * @return amountOut Quantidade de tokens de saída calculada.
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    /**
     * @notice Calcula a quantidade de entrada necessária para obter uma quantidade de saída, considerando as reservas e taxas.
     * @dev Usado para estimar a entrada necessária para um swap, incluindo taxas do Uniswap (0,3%).
     *      Fórmula: amountIn = (reserveIn * amountOut * 1000) / (reserveOut - amountOut * 997) + 1.
     * @param amountOut Quantidade de tokens de saída desejada.
     * @param reserveIn Reserva de tokens de entrada no par.
     * @param reserveOut Reserva de tokens de saída no par.
     * @return amountIn Quantidade de tokens de entrada requerida.
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    /**
     * @notice Calcula as quantidades de saída para um caminho de swap com uma quantidade de entrada.
     * @dev Itera sobre o caminho (`path`) para calcular as saídas em cada par, considerando taxas.
     * @param amountIn Quantidade de tokens de entrada.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    /**
     * @notice Calcula as quantidades de entrada necessárias para um caminho de swap com uma quantidade de saída desejada.
     * @dev Itera sobre o caminho (`path`) para calcular as entradas necessárias em cada par, considerando taxas.
     * @param amountOut Quantidade de tokens de saída desejada.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @return amounts Lista de quantidades processadas em cada etapa do swap.
     */
    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}