//
//  Training.swift
//  Pods
//
//  Created by Guled  on 2/23/17.
//
//

import Foundation
import Upsurge

/// The Training Protocol defines the methods used for training a NeuralNet Object. Note that the `train` method used in this protocol's extension is used only for Neural Network architectures such as Adaline and Perceptron. There is no backpropagation method within the Training method. The Backpropagation class utilizes the Training protocol in order to implement methods that pertain to printing/debugging values. The Backpropagation algorithm has it's own 'train' method. The way the Adaline and Perceptron architecture's perform weight updates and training are completely different from the techniques found in Backpropagation which is why I have separated them.
public protocol Training {
    func train(network: NeuralNet) -> NeuralNet

}

extension Training {

    // MARK: - Public Methods

    /**
     The train method trains your Neural Network object. WARNING: Use this method only for Perceptron and Adaline architectures.
     The Backpropagation class has it's own train method.

     - parameter fncType: ActivationFunctionType enum case.
     - parameter value: A Float.

     - returns: A Float.
     */
    public func train(network: NeuralNet) -> NeuralNet {

        var weightsComingIn: ValueArray<Float>! = ValueArray<Float>()

        var rows = network.trainingSet.rows
        var columns = network.trainingSet.columns

        var error: Float = 0.0
        var meanSquaredError: Float = 0.0

        for epochs in 0..<network.maxEpochs {

            var estimatedOutput: Float!
            var actualOutput: Float!

            for i in 0..<rows {

                var netValue: Float = 0

                for j in 0..<columns {
                    weightsComingIn = network.inputLayer.listOfNeurons[j].weightsComingIn
                    var inputWeight = weightsComingIn[0]
                    netValue += inputWeight * network.trainingSet[i, j]
                }

                // Estimate the error of our model
                estimatedOutput = try! NNOperations.activationFunc(fncType: network.activationFuncType, value: netValue)
                actualOutput = network.targetOutputSet[i]

                error = actualOutput - estimatedOutput

                // Weight adjustment if error is not satisfactory
                if abs(error) > network.targetError {

                    let neurons = teachNeuronOfLayer(numberOfInputNeurons: columns, line: i, network: network, netValue: netValue, error: error)
                    var inputLayer = InputLayer(neurons: neurons)

                    network.inputLayer = inputLayer
                }

            }

            meanSquaredError = powf(actualOutput - estimatedOutput, 2.0)
            network.meanSquaredErrorList.append(meanSquaredError)
        }

        network.trainingError = error

        return network
    }

    /**
     The printTrainedNetwork method prints the results of a trained Neural Network object.

     - parameter trainedNetwork: A trained Neural Network Object.
     - parameter singleLayer: Boolean to indicate whether or not your Neural Network has multiple layers.

     */
    public func printTrainedNetwork(trainedNetwork: NeuralNet, singleLayer: Bool) {

        if singleLayer {
            printSingleLayerNetworkResult(trainedNetwork: trainedNetwork)
        } else {
            printMultiLayerNetworkResult(trainedNetwork: trainedNetwork)
        }

    }

    // MARK: - Private Methods

    private func teachNeuronOfLayer(numberOfInputNeurons: Int, line: Int, network: NeuralNet, netValue: Float, error: Float) -> [Neuron] {

        var listOfNeurons: [Neuron] = []
        var inputWeightsInOld: ValueArray<Float> = ValueArray<Float>()
        var inputWeightsInNew: [Float] = []

        for var j in 0..<numberOfInputNeurons {
            inputWeightsInOld = network.inputLayer.listOfNeurons[j].weightsComingIn
            var oldWeight = inputWeightsInOld[0]

            inputWeightsInNew.append(try! updateWeight(trainingType: network.trainingType, oldWeight: oldWeight, network: network, error: error, trainSample: network.trainingSet[line, j], netValue: netValue))

            var newNeuron = Neuron()
            newNeuron.weightsComingIn = ValueArray(inputWeightsInNew)

            listOfNeurons.append(newNeuron)
            inputWeightsInNew = []
        }

        return listOfNeurons
    }

    private func updateWeight(trainingType: TrainingType, oldWeight: Float, network: NeuralNet, error: Float, trainSample: Float, netValue: Float) throws -> Float {

        switch trainingType {
        case .perceptron:
            return oldWeight + network.learningRate * error * trainSample
        case .adaline:
            return oldWeight + network.learningRate * error * trainSample * (try! NNOperations.derivativeFunc(fncType: network.activationFuncType, value: netValue))
        default:
            throw MachineLearningError.invalidInput
        }

    }

    // TODO: REVISE FOR GENERAL NEURAL NETWORK RESULT
    private func printMultiLayerNetworkResult(trainedNetwork: NeuralNet) {

        var rows = trainedNetwork.trainingSet.rows
        var columns = trainedNetwork.trainingSet.columns

        var weightsComingIn: ValueArray<Float>! = ValueArray<Float>()

        for i in 0..<rows {

            var netValue: Float = 0

            for j in 0..<columns {
                weightsComingIn = trainedNetwork.inputLayer.listOfNeurons[j].weightsComingIn
                var inputWeight = weightsComingIn[0]
                netValue += inputWeight * trainedNetwork.trainingSet[i, j]

                print("\(trainedNetwork.trainingSet[i, j])")
            }

            print("\n")
            var estimatedOutput = try! NNOperations.activationFunc(fncType: trainedNetwork.activationFuncType, value: netValue)

            var colsOutput: Int = trainedNetwork.targetOutputMatrix.columns

            var realOutput: Float = 0.0

            for var k in 0..<colsOutput {

                print(trainedNetwork.targetOutputMatrix[i, k])
                realOutput += trainedNetwork.targetOutputMatrix[i, k]
            }

            print(" NET OUTPUT: \(estimatedOutput)")
            print(" REAL OUTPUT: \(realOutput)")

            var error: Float = estimatedOutput - realOutput
            print(" ERROR: \(error)")

            print("------------------------------------")
        }

    }

    private func printSingleLayerNetworkResult(trainedNetwork: NeuralNet) {
        var trainedNetwork = trainedNetwork

        var rows = trainedNetwork.trainingSet.rows
        var columns = trainedNetwork.trainingSet.columns

        var weightsComingIn: ValueArray<Float>! = ValueArray<Float>()

        for i in 0..<rows {

            var netValue: Float = 0

            for j in 0..<columns {
                weightsComingIn = trainedNetwork.inputLayer.listOfNeurons[j].weightsComingIn
                var inputWeight = weightsComingIn[0]
                netValue += inputWeight * trainedNetwork.trainingSet[i, j]

                print("\(trainedNetwork.trainingSet[i, j])")
            }

            print("\n")
            var estimatedOutput = try! NNOperations.activationFunc(fncType: trainedNetwork.activationFuncType, value: netValue)

            trainedNetwork.estimatedOutputAsArray.append(estimatedOutput)

            print("NET OUTPUT: \(estimatedOutput) \t")

            print("REAL OUTPUT: \(trainedNetwork.targetOutputSet[i]) \t")

            var error = estimatedOutput - trainedNetwork.targetOutputSet[i]

            print("ERROR: \(error) \t")

            print("------------------------------------")
        }

    }
}
