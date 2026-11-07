export interface UseCase<Input, Output> {
    handle(params: Input): Output
}