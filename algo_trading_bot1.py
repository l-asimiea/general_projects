"""
TITLE: 
A simple energy asset algorithm trading bot  

DESCRIPTION: 
This code depicts an algorithmic trading bot that focuses on
5 energy assets, and the implementation of a simple moving average
crossover strategy to realise gains.
 
The trading strategy is such that buy signals are created when the 
short-term moving average crosses above the long-term moving average and 
sell signals are created when the short-term moving average crosses 
below the long-term moving average.
Back testing the strategy on a 3 year historical data starting from 01/01/2020
using an initial investment of £10,000 yeilded an energy asset portfolio 
cumulative return of 2.34%. 

Possible progressions of this work can involve the following:
(i)     Expansion of the portfolio to include more energy assets and 
        re-evaluating the portfolio value 
(ii)    A comparison of this strategy to other strategies as part of a 
        static or dynamic strategy selection process. 

AUTHOR: 
Laurel Asimiea
"""

#%% STEP 1: IMPORT REQUIRED LIBRARIES
import numpy as np
import pandas as pd
import yfinance as yf 

# For visuals using Bokeh
from bokeh.io import output_file,show,push_notebook
from bokeh.plotting import figure
from bokeh.models import HoverTool, ColumnDataSource
from bokeh.layouts import column

# For visuals using Plotly
# import plotly.express as px 

#%% STEP 2: GET HISTORICAL ENERGY ASSET DATA

# Target energy assets:
    # XLE:  Energy Select Sector SPDR Fund 
    # USO:  United States Oil Fund (Crude Oil)
    # UNG:  United States Natural Gas Fund
    # EZJ:  iShares STOXX Europe 600 Oil & Gas UCITS ETF (Oil & Gas - Europe)
    # SIE.DE:   Siemens Energy 
tickers = ['XLE', 'USO', 'UNG', 'EZJ', 'SIE.DE'] 

data = yf.download(tickers, start='2020-01-01', end='2023-01-01')['Adj Close']

# Get short and long term windows using moving avargaes for energy assets 
short_window = 40         # 40 days
long_window = 100         # 100 days

for tick in tickers:
    data[f'{tick}_Short_MA40'] = data[tick].rolling(window=short_window, min_periods=1).mean()
    data[f'{tick}_Long_MA100'] = data[tick].rolling(window=long_window, min_periods=1).mean()


#%% STEP 3: CREATE BUY AND SELL SIGNALS

# 1st create a dataframe to store signals
signals = pd.DataFrame(index=data.index)

# Then populate the empty dataframe with the target signals as well as buy & sell triggers
for tick in tickers:
    signals[f'{tick}_price'] = data[tick]
    signals[f'{tick}_short_ma40'] = data[f'{tick}_Short_MA40']
    signals[f'{tick}_long_ma100'] = data[f'{tick}_Long_MA100']
    
    # Create buy and sell triggers
    signals[f'{tick}_signal'] = 0
    signals[f'{tick}_signal'][short_window:] = np.where(signals[f'{tick}_short_ma40'][short_window:]
                                                        > signals[f'{tick}_long_ma100'][short_window:],1,0)
    signals[f'{tick}_positions'] = signals[f'{tick}_signal'].diff()
    
    
#%% STEP 4: CREATE A BACKTEST STRATEGY TO EVALUATE POSTERIOR VIEW PERFORMANCE

# Using an inital capital of £10,000, create a portfolio of the assets
initial_capital = float(10000.0)

portfolio = pd.DataFrame(index=signals.index)
portfolio['cash'] = initial_capital

for tick in tickers:
    portfolio[f'{tick}_positions'] = signals[f'{tick}_positions']
    portfolio[f'{tick}_price'] = signals[f'{tick}_price']
    portfolio[f'{tick}_holdings'] = signals[f'{tick}_positions'].cumsum() * signals[f'{tick}_price']
    portfolio['cash'] -= portfolio[f'{tick}_holdings'].diff().fillna(0)
    
# Calculate the value of the portfolio of assets
portfolio['total'] = portfolio['cash'] + portfolio[[f'{tick}_holdings' for tick in tickers]].sum(axis=1)
portfolio['returns'] = portfolio['total'].pct_change()
portfolio['cumulative_returns'] = (1 + portfolio['returns']).cumprod() - 1  

#%% STEP 5: VISUAL RESULTS 

# Plot the values of the portfolio and signals
source_data = ColumnDataSource(portfolio)

plot = figure(title='Portfolio Value Over Time', 
                x_axis_label='Date',
                y_axis_label='Portfolio Value',
                x_axis_type='datetime',
                width=800, height=400)

plot.line('index', 'total', source=source_data, legend_label='Portfolio Value', line_width=2, color='blue')

#include the buy & sell signals to the plot
for tick in tickers:
    buy_signals = signals[signals[f'{tick}_positions']== 1.0].index
    sell_signals = signals[signals[f'{tick}_positions']== -1.0].index
    plot.triangle(x=buy_signals, y=signals.loc[buy_signals,f'{tick}_price'], size=10, color='green', alpha=0.6,
                  legend_label=f'{tick} Buy Signal')
    plot.inverted_triangle(x=sell_signals, y=signals.loc[sell_signals,f'{tick}_price'], size=10, color='green', alpha=0.6,
                  legend_label=f'{tick} Sell Signal')

# include hover tool and show the plot
hover = HoverTool()
hover.tooltips = [("Date", "@index{%F}"), ("Value", "total{$0.2f}")]
hover_formatters = {"@index": "datetime"}
plot.add_tools(hover)
output_file('portfolio_value.hmtl')
show(plot)

#%% STEP 6: PRINT THE FINAL PORTFOLIO VALUE

final_portfolio_value = portfolio['total'][-1]
cumulative_portfolio_returns = portfolio['cumulative_returns'][-1]

# print
print(f'Final Portfolio Value: £{final_portfolio_value:.2f}')
print(f'Cumulative Returns: {cumulative_portfolio_returns:.2%}')



""" END OF CODE """
 

