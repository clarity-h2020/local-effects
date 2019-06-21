import numpy as np
import math

#### CONFIGURATION ####

city = 'Naples'
'''
DATA DEPENDENT ON NAPLES
These should come from the DB or the CSIS or some place where this configuration is stored
T_a = 305.15 K #32C for a certain heat wave instensity, will change for different cities and
 scenarios
epsilon_sky = 0.0028 * (T_a - 273.15) + 0.787
theta = 137.2
eta = 67.9
'''
T_a = 305.15
epsilon_sky = 0.0028 * (T_a - 273.15) + 0.787
theta = 137.2
eta = 67.9

# CONSTANTS
sigma = 5.67e-8     # Stefan-Boltzmann constant
Xi_k = 0.7          # absortion coefficient for shortwave radiation
epsilon_p = 0.97    # body 

#### END CONFIGURATION ####

'''
FROM JSON (works as the storage for layer info):
alpha = albedo
epsilon_surface = surface emissivity
epsilon_wall = wall emissivity
phi_b = hillshade building
phi_v = hillshade green
Sv = vegetation shadow
Sb = building shadow  FIXME: Needs to change based on the layer
G = global shortwave radiation
I = direct shortwave radiation
D = diffuse shortwave radiation
tau = transmissivity
'''
import json


def get_shortwave_radiation_fluxes(G, Sb, Sv, tau, eta, phi_b, phi_v, alpha):
    '''
    Shortwave radiation flux calculation
    '''
    I = 0.9 * G
    D = 0.1 * G
    
    # K_l
    # K_l1 = I * [Sb - (1-Sv)*(1-tau)] * math.sin(eta) * math.cos(theta)
    K_l1 = I * (Sb - (1 - Sv) * (1 - tau)) * math.cos(eta)
    K_l2 = D * (phi_b - (1 - phi_v) * (1 - tau))
    K_l3 = G * alpha * 0.5 * (1 - (phi_b - (1 - phi_v) * (1 - tau)))
    # K_in
    K_in1 = I * (Sb - (1 - Sv) * (1 - tau)) * math.sin(eta)
    K_in2 = D * (phi_b - (1 - phi_v) * (1 - tau))
    K_in3 = G * alpha * 0.5 * (1 - (phi_b - (1 - phi_v) * (1 -tau)))

    # Put these in an array of the form: above, below, south, north, east, west
    K = np.array([K_in1 + K_in2, K_in2 + K_in3, K_l1 + K_l2 + K_l3, \
                    K_l2 + K_l3, K_l2 + K_l3, K_l2 + K_l3])
    return K

def get_longwave_radiation_fluxes(phi_b, phi_v, sigma, T_a, epsilon_sky, epsilon_wall, epsilon_surface, Ts):
    '''
    Longwave radiation flux calculation
    '''
    L_1 = -(1 - phi_b - phi_v) * epsilon_sky * sigma * T_a**4
    L_2 = (2 - phi_v - phi_b) * sigma * epsilon_wall * Ts**4
    L_3 = (-phi_v - phi_b) * sigma * epsilon_wall * Ts**4
    L_4 = (2 - phi_b - phi_v) * (1 - 0.7) * sigma * epsilon_sky * T_a**4
    L_out = epsilon_surface * sigma * (Ts + (Ts - T_a))**4
    L_l = L_out * 0.5
    # Put these in an array of the form: above, below, south, north, east, west
    L = np.array([L_1, L_3, L_2 + L_4 + L_l, L_2 + L_4 + L_l, \
                    L_2 + L_4 + L_l, L_2 + L_4 + L_l])
    return L

def get_mean_radiant_fluxes(shortwave_flux, longwave_flux, F_i, Xi_k=0.7):
    # Determine the K related term of the mean radiant flux density (R)
    Rk = Xi_k * np.sum(shortwave_flux * F_i)
    # Determine the L related term of the mean radiant flux density (R)
    Lk = epsilon_p * np.sum(longwave_flux * F_i)
    return Rk + Lk

def get_temperature_for_layer(mean_flux, sigma, epsilon_p=0.97):
    Tmrti = (mean_flux / (epsilon_p*sigma))**(1/4) - 273.15
    return Tmrti 


if __name__ == '__main__':
    # Features: water roads railways trees vegetation agricultural_areas
    # built_up built_open_spaces dense_urban_fabric medium_urban_fabric low_urban_fabric
    # public_military_industrial

    # From some input we get a list of all the features needed and we will determine the
    # values of a set of parameters for the selected city

    # This process will be repeated for each cell, we'll have a Tmrt in each cell

    layers = ["Water", "Roads", "Railways", "Trees", "Vegetation", "Agricultural areas", \
                "Built-up", "Built open spaces", "Dense Urban Fabric", "Medium Urban Fabric", \
                "Low Urban Fabric", "Public, military, industrial"]
    # Angular factors
    F_i = np.array([0.06, 0.06, 0.22, 0.22, 0.22, 0.22])
    num_layers = 12
    Tmrt_array = np.zeros(num_layers)
    for i in range(num_layers):
        layer_name = layers[i]
        with open('layer_parameters.json') as json_data_file:
            layer_info = json.load(json_data_file)[layer_name]
        
        # FIXME: DATA THAT SHOULD BE AN INPUT 
        # Some of these parameters will be different for each layer/cell based on the 
        # calculations described in the excel.
        # For convenience they are just used here with fixed values from the JSON file
        alpha = layer_info['albedo']
        epsilon_surface = layer_info["surface emissivity"]
        epsilon_wall = layer_info["wall emissivity"]
        tau = layer_info["transmissivity"]
        Sv = layer_info["vegetation shadow"]
        Sb = layer_info["building shadow"] 
        phi_b = layer_info["hillshade building"]
        phi_v = layer_info["hillshade green"]
        G = layer_info["global shortwave radiation"]
        T_delta = layer_info["surface temperature delta"]
        Ts = T_a + T_delta
    
        layer_name = layers[i]
        shortwave_flux = get_shortwave_radiation_fluxes(G, Sb, Sv, tau, eta, phi_b, phi_v, alpha)
        longwave_flux = get_longwave_radiation_fluxes(phi_b, phi_v, sigma, T_a, epsilon_sky, epsilon_wall, epsilon_surface, Ts)
        mean_flux = get_mean_radiant_fluxes(shortwave_flux, longwave_flux, F_i)
        Tmrt_array[i] = get_temperature_for_layer(mean_flux, sigma)
    
    # These are the percentages calculated for each layer. Now a set of dummy values
    P_array = np.random.random_sample(12)
    print(P_array)
    print(Tmrt_array)
    # If a cell is just a gap, nothing is in here, P_array will be null or zero or 
    # NAN and Tmrt will be NAN or null, whatever is deemed the best option
    Tmrt = sum(P_array * Tmrt_array)/sum(P_array)
    print(Tmrt)
