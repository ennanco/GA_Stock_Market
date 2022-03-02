function f = get_fitness_function(stocks_prices, initial_amount, days)
%This function returns another function which in fucntion of the movements
%on the wallet will return the possible profit from an initial amount
    avg_stocks = movmean(stocks_prices, [0, days-1],'Endpoints', 'discard');
    std_stocks = movstd(stocks_prices, [0, days-1], 'Endpoints', 'discard');
    function fn = fitness_function(individual)

        %General setup
        [n_days, n_stocks] = size(stocks_prices);
        portfolio = zeros(1,n_stocks);
        cash = initial_amount;

        %Take the threshold from the individual for  each  share
        strong_sell_threshold = individual(1:4:end);
        weak_sell_threshold = individual(2:4:end);
        weak_buy_threshold = individual(3:4:end);
        strong_buy_threshold = individual(4:4:end);

        positions = n_days - days + 1;
        
        %Define the selling and buy orders
        strong_sold_orders = stocks_prices(days:end, :) > avg_stocks + repmat(strong_sell_threshold, positions , 1).*std_stocks;
        weak_sold_orders = stocks_prices(days:end, :) > avg_stocks + repmat(weak_sell_threshold, positions, 1).*std_stocks;
        weak_buy_orders = stocks_prices(days:end, :) < avg_stocks - repmat(weak_buy_threshold,  positions,1).*std_stocks;
        strong_buy_orders = stocks_prices(days:end, :) < avg_stocks - repmat(strong_buy_threshold, positions,1).*std_stocks;

        %Remove order that overlaps
        %when strong and weak  order are set, then only moderate/weak orders are kept. 
        weak_sold_orders(strong_sold_orders & weak_sold_orders) = 0;
        weak_buy_orders(strong_buy_orders & weak_buy_orders) = 0;

        previous_days = days -1;
        
        %Simulate the process
        for day = 1:(n_days - previous_days)
            %Perform the sells first in order to have money to operate on the next
            for stock = 1:n_stocks
                if strong_sold_orders(day, stock) %Stop-Gain
                    cash = cash + portfolio(stock)*stocks_prices(day + previous_days, stock);
                    portfolio(stock) = 0;
                elseif weak_sold_orders(day,stock) %moderate oportunity
                    cash = cash + min(portfolio(stock), 50)*stocks_prices(day + previous_days, stock);
                    portfolio(stock) = portfolio(stock) - min(portfolio(stock), 50);
                end
            end
            %Next step perfom moderate purchase orders
            for stock = 1:n_stocks
                if weak_buy_orders(day, stock)
                    shares = min(50, floor(cash/stocks_prices(day+previous_days, stock)));
                    cash = cash - shares*stocks_prices(day+previous_days, stock);
                    portfolio(stock) = portfolio(stock) + shares;
                end
            end
            %Great oportunities choose only one and buy as much as you can
            if any(strong_buy_orders(day, :))
                stock = (find(strong_buy_orders(day, :)));
                stock = stock(1);
                shares = floor(cash/stocks_prices(day + previous_days, stock));
                cash = cash - shares*stocks_prices(day+previous_days, stock);
                portfolio(stock) = portfolio(stock) + shares;
            end
        end

        % calculate the result at the end
        fn = - (cash + portfolio*stocks_prices(end, :)');
    end

    f = @fitness_function;

end
